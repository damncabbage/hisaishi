require 'rubygems'
require 'sinatra'
require 'sinatra/jsonp'
require 'natural_time'
require 'sinatra-websocket'

# Pulls in settings and required gems.
require File.expand_path('environment.rb', File.dirname(__FILE__))

# Base hisaishi functionality
use Rack::Session::Cookie
apply_csrf_protection unless settings.environment == :test


# ##### WEBSOCKET ROUTES

set :server, 'thin'
set :sockets, []

get '/socket' do
  if !request.websocket?
    redirect '/'
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send({type: 'hi'}.to_json)
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        
        puts msg
        
        EM.next_tick do
          # Spam the message back out to all connected clients, player and controller alike.
          settings.sockets.each do |s|
            s.send(msg)
          end
        end
      end
      ws.onclose do
        ws.send({type: 'bye'}.to_json)
        settings.sockets.delete(ws)
      end
    end
  end
end

def send_to_sockets(type, data={})
  settings.sockets.each do |ws|
    ws.send({:type => type, :data => data}.to_json)
  end
end

# ##### PULLS IN INCLUDED ROUTES

require File.expand_path('HisaishiQueuePlayer.rb', File.dirname(__FILE__))

# ##### PLAYER ROUTES

get '/' do
  authenticate

  if settings.defaults_to_queue
    redirect '/lock-screen'
  else
    song = rand_song

    if song
      haml :song, :locals => { :song_json => song.json, :user => session[:username] }
    else
      haml :no_song
    end
  end
end

get '/song/:song_id' do
  authenticate

  song = Song.get(params[:song_id])

  if song
    haml :song, :locals => { :song_json => song.json, :user => session[:username] }
  else
    haml :no_song
  end
end

post '/song/:song_id/vote' do
  authenticate!

  song = Song.get(params[:song_id])
  song.vote(params[:vote], params[:reasons], session)

  return true
end

get '/songs/list' do
  authenticate

  songs = Song.all
  haml :song_list, :locals => {:songs => songs}
end

get '/songs/list.jsonp' do
  songs = Song.all
  JSONP songs
end

get '/login' do
  redirect '/' if is_logged_in

  haml :login
end

post '/login' do
  host = settings.basecamp_domain + '.basecamphq.com'
  begin
    Basecamp.establish_connection! host, params[:username], params[:password], true
    token = Basecamp.get_token
    session[:username] = params[:username] unless token.nil?
  rescue ArgumentError
  end

  if is_logged_in
    redirect session.delete(:intended_url)
  else
    redirect '/login'
  end
end

get '/logout' do
  session.clear
  redirect '/login'
end

get '/proxy' do
  url = params[:url]
  puts 'The URL was: ' + url
  open(URI.encode(url).gsub('[', '%5B').gsub(']', '%5D')).read
end


# ##### CONTROLLER ROUTES

# Browser

get '/browse' do
  haml :browser
end

# Search

get '/search' do
  haml :search, :locals => {
    :authed => has_admin_pin
  }
end

post '/search' do
  songs = Song.search(params[:q])
  haml :search_result, :locals => {
    :songs => songs
  }
end

# Queue

get '/queue' do
  pin_auth
  q = queue_songs
  q[:authed] = has_admin_pin
  haml :queue, :locals => q
end

get '/queue-info/:q_id' do
  pin_auth!
  q = HisaishiQueue.get(params[:q_id])
  song = Song.get(q.song_id)
  haml :queue_info, :locals => {
    :song => song,
    :q => q
  }
end

post '/queue-info-process' do
  pin_auth!
  q = HisaishiQueue.get(params[:q_id])
  puts params[:action]

  trigger_action = "queue_update"
  case params[:action]
  when "now"
    q.play_now
    trigger_action = "play"
  when "next"
    q.play_next
  when "last"
    q.play_last
  when "stop"
    q.stop
    trigger_action = "stop"
  when "prep"
    q.prep
  when "play_next"
    q.play_next_now
    trigger_action = "play"
  when "pause"
    q.pause
    trigger_action = "pause"
  when "unpause"
    q.unpause
    trigger_action = "play"
  end

  # Tell the player we moved its cheese.
  send_to_sockets(trigger_action, {
    :for => "player",
    :queue_id => params[:q_id],
    :action => params[:action]
  })

  redirect '/queue'
end

get '/queue.jsonp' do
  pin_auth!
  out = queue_songs
  JSONP out
end

get '/queue-delete/:q_id' do
  pin_auth!
  q = HisaishiQueue.get(params[:q_id])
  song = Song.get(q.song_id)
  haml :queue_delete_confirm, :locals => {
    :song => song,
    :q => q
  }
end

post '/queue-delete-process' do
  pin_auth!
  q = HisaishiQueue.get(params[:q_id])
  q.destroy
  
  send_to_sockets("queue_update", {
    :for => "player",
    :action => "delete",
    :queue_id => params[:q_id]
  })
  
  redirect '/queue'
end

post '/queue-reorder' do
  pin_auth!
  unless params[:queue].nil?
    reorder_queue(params[:queue])

    send_to_sockets("queue_update", {
      :for => "player",
      :action => "reorder",
      :queue => params[:queue]
    })
    
  end
end

# Add song

get '/add/:song_id' do
  song = Song.get(params[:song_id])
  haml :queue_song, :locals => {
    :song => song,
    :authed => has_admin_pin
  }
end

post '/add-submit' do
  song = Song.get(params[:song_id])

  last_q = last_song_by_requester(params[:requester])
  diff = nil
  if !last_q.nil? then
    diff = Time.now - last_q.created_at
  end

  if !has_admin_pin and !last_q.nil? and diff.round <= 300 then
    haml :queue_song_fail_limit, :locals => {
      :requester => params[:requester],
      :song => song,
      :diff => NaturalTime.new(diff).to_sentence,
      :authed => has_admin_pin
    }
  else
    new_queue = song.enqueue(params[:requester])
  
    send_to_sockets("queue_update", {
      :for => "player",
      :action => "add",
      :song_id => params[:song_id]
    })

    haml :queue_song_ok, :locals => {
      :song => song,
      :new_queue => new_queue,
      :authed => has_admin_pin
    }
  end
end

# DEPRECATED
post '/queue-submit' do
  authenticate!

  song = Song.get(params[:song_id])
  new_queue = song.enqueue(params[:requester])

  haml :enqueue_ok, :locals => { :song_title => song.title, :requester => new_queue.requester }
end

get '/songinfo/:song_id' do
  authenticate!

  song = Song.get(params[:song_id])
  data = song.get_data!
  puts data
  puts data.length.ceil
end

# Announcements

get '/announce' do
  pin_auth

  anns = Announcement.all(:order => [ :ann_order.asc ])
  haml :announce, :locals => {
    :announce => anns,
      :authed => has_admin_pin
  }
end

get '/announce.jsonp' do
  pin_auth!

  anns = Announcement.all(:order => [ :ann_order.asc ])
  JSONP anns
end

post '/announce' do
  text = params[:text]
  new_ann = Announcement.create(
    :text => text,
    :ann_order => Announcement.all.length,
    :authed => has_admin_pin
  )
  redirect '/announce'
end

get '/announce-add' do
  pin_auth!
  haml :announce_add
end

post '/announce-add-process' do
  pin_auth!

  a = Announcement.create(
    :text       => params[:text],
    :ann_order     => Announcement.all.length,
    :displayed    => params[:show_now] != '1'
  )

  normalise_announcement_order

  redirect '/announce'
end

get '/announce-delete/:a_id' do
  pin_auth!
  a = Announcement.get(params[:a_id])
  haml :announce_delete_confirm, :locals => {
    :ann => a
  }
end

post '/announce-delete-process' do
  pin_auth!
  a = Announcement.get(params[:a_id])
  a.destroy
  normalise_announcement_order
  redirect '/announce'
end

post '/announce-reorder' do
  pin_auth!
  unless params[:announce].nil?
    reorder_announcements(params[:announce])
  end
end

get '/announce-show-now/:a_id' do
  pin_auth!
  a = Announcement.get(params[:a_id])
  a.show_now
  normalise_announcement_order
  redirect '/announce'
end

get '/announce-hide-now/:a_id' do
  pin_auth!
  a = Announcement.get(params[:a_id])
  a.shown
  normalise_announcement_order
  redirect '/announce'
end

# Diagnostics

get '/diagnostic' do
  pin_auth
  puts request.env.inspect
  haml :diagnostic, :locals => {
  :scheme => request.env["rack.url_scheme"],
    :host => request.env["HTTP_HOST"],
    :ip => IPSocket.getaddress(Socket.gethostname)
  }
end

# PIN auth screen

get '/lock-screen' do
  session.clear
  return_path = params[:return_path].nil? ? 'queue' : params[:return_path]
  haml :pin_entry, :locals => {
    :return_path => return_path
  }
end

post '/unlock-screen' do
  session[:admin_pin] = params[:pin]
  state = {
    :authed => has_admin_pin
  }
  JSONP state
end


# ##### HELPER FUNCTIONS

# Login helper functions

def authenticate
  session[:intended_url] = request.url
  redirect '/login' unless is_logged_in
end

def authenticate!
  halt(403, 'You are not logged in.') unless is_logged_in
end

def is_logged_in
  unless settings.basecamp_domain
    session[:username] = 'guest'
  end
  session[:username] # Nil if not set, otherwise truthy.
end

# PIN auth helper functions

def pin_auth
  session[:intended_url] = request.url
  redirect '/lock-screen' unless has_admin_pin
end

def pin_auth!
  halt(403, 'You are not logged in.') unless has_admin_pin
end

def has_admin_pin
  unless settings.admin_pin
    return false
  end
  return session[:admin_pin] == settings.admin_pin
end

# DB Helper

# Queueing

def queue_songs
  song_list = {}
  HisaishiQueue.all.each do |q|
    s = Song.get(q.song_id)
    song_list[s.id] = s.player_data
  end

  {
    :songs => song_list,
    :queue => HisaishiQueue.all(:order => [:queue_order.asc])
  }
end

def reorder_queue(queue_ids)
  i = 0
  queue_ids.each do |q_id|
    q = HisaishiQueue.get(q_id);
    q.update(:queue_order => i)
    i += 1
  end
end

# Announcements

def normalise_announcement_order
  ids = []
  Announcement.all(:order => [:ann_order.asc]).each do |a|
    ids << a.id
  end
  reorder_announcements(ids)
end

def reorder_announcements(announce_ids)
  i = 0
  announce_ids.each do |a_id|
    a = Announcement.get(a_id);
    a.update(:ann_order => i)
    i += 1
  end
end

# Song addition

def last_song_by_requester(requester)
  HisaishiQueue.first(
    :requester => requester,
    :order => [ :created_at.desc ]
  )
end

# Song search

def rand_song
  songs = Song.find_by_sql([
   'SELECT * FROM songs
    WHERE "id" NOT IN (
      SELECT "song_id" FROM votes
      WHERE "user" = ?
      GROUP BY "song_id" HAVING COUNT(*) > 0
    )
    AND "no" < 1 AND "yes" < 3
    ORDER BY RANDOM();',
    session[:username]
  ])

  if songs.length > 0
    return songs.pop
  else
    return false
  end
end


