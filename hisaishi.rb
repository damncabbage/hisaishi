require 'rubygems'
require 'sinatra'
require 'sinatra/jsonp'
require 'natural_time'
require 'sinatra-websocket'
require 'fileutils'

# Pulls in settings and required gems.
require File.expand_path('environment.rb', File.dirname(__FILE__))

# Base hisaishi functionality
use Rack::Session::Cookie
# apply_csrf_protection unless settings.environment == :test

# ##### WEBSOCKET ROUTES

set :server, 'thin'
set :sockets, []

hi_json = {type: 'hi'}.to_json
bye_json = {type: 'bye'}.to_json

get '/socket' do
  if !request.websocket?
    redirect '/'
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send(hi_json)
        settings.sockets << ws
      end
      ws.onmessage do |msg| 
        EM.next_tick do
          # Spam the message back out to all connected clients, player and controller alike.
          settings.sockets.each do |s|
            s.send(msg)
          end
        end
      end
      ws.onclose do
        ws.send(bye_json)
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
  if settings.defaults_to_queue
    redirect '/lock-screen'
  else
    redirect '/player'
  end
end

get '/songs/list' do
  pin_auth

  songs = Song.all
  haml :song_list, :locals => {:songs => songs}
end

get '/songs/list.jsonp' do
  songs = Song.all
  JSONP songs
end

get '/proxy' do
  url = params[:url]
  begin
    path = URI.encode(url).gsub('[', '%5B').gsub(']', '%5D')
    if path[0] == '/' then
      path = 'http://localhost:4567' + path
    end
    open(path).read
  rescue OpenURI::HTTPError => bang
    'None'
  rescue StandardError => bang
    'None'
  end
end

# ##### MEDIA ROUTES

get '/song/:song_id/audio.mp3' do
  song = Song.get(params[:song_id])
  if !song.nil? then
    audio_path = song.local_audio_path
    if !audio_path.nil? then
      send_file(audio_path)
    else
      begin
        open(song.audio_path).read[0, 50]
        if io.status[0] == "200" then
          redirect song.audio_path
        else
          halt(404, "Audio not found.")
        end
      rescue StandardError => bang
        halt(404, "Audio not found.")
      end
    end
  else
    halt(404, "Song not found.")
  end
end

get '/song/:song_id/lyrics.txt' do
  song = Song.get(params[:song_id])
  if !song.nil? then
    lyrics_path = song.local_lyrics_path
    if !lyrics_path.nil? then
      puts lyrics_path
      send_file(lyrics_path)
    else
      begin
        open(song.lyrics_path).read[0, 50]
        if io.status[0] == "200" then
          redirect song.lyrics_path
        else
          'None'
        end
      rescue StandardError => bang
        'None'
      end
    end
  else
    halt(404, "Song not found.")
  end
end

get '/song/:song_id/image' do
  song = Song.get(params[:song_id])
  if !song.nil? then
    image_path = song.local_image_path
    if !image_path.nil? then
      send_file(image_path)
    else
      begin
        open(song.image_path).read[0, 50]
        if io.status[0] == "200" then
          redirect song.image_path
        else
          halt(404, "Image not found.")
        end
      rescue StandardError => bang
        halt(404, "Image not found.")
      end
    end
  else
    halt(404, "Song not found.")
  end
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
  puts q
  q[:authed] = has_admin_pin
  haml :queue, :locals => q
end

get '/queue-info/:q_id' do
  pin_auth!
  q = HisaishiQueue.get(params[:q_id])
  puts q
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
    trigger_action = "unpause"
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

post '/queue-info-update' do
  result = false
  unless params[:queue_id].nil? && params[:state].nil?
    q = HisaishiQueue.get(params[:queue_id])
    unless q.nil? then
      q.update(:play_state => params[:state])
      
      send_to_sockets("admin_update", {
        :for => "admin",
        :action => "state_update",
        :queue_id => params[:queue_id],
        :state => params[:state]
      })
      
      result = true
    end
  end
  {:result => result}.to_json
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

get '/songinfo/:song_id' do
  pin_auth!

  song = Song.get(params[:song_id])
  data = song.get_data!
  #puts data
  #puts data.length.ceil
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
  
  send_to_sockets("announcements", {
    :for => "announcements",
    :action => "update"
  })
  
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
  
  send_to_sockets("announcements", {
    :for => "announcements",
    :action => "update"
  })

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
  
  send_to_sockets("announcements", {
    :for => "announcements",
    :action => "update"
  })
  
  redirect '/announce'
end

post '/announce-reorder' do
  pin_auth!
  unless params[:announce].nil?
    reorder_announcements(params[:announce])
  end
  
  send_to_sockets("announcements", {
    :for => "announcements",
    :action => "update"
  })
end

get '/announce-show-now/:a_id' do
  pin_auth!
  a = Announcement.get(params[:a_id])
  a.show_now
  normalise_announcement_order
  send_to_sockets("announcements", {
    :for => "announcements",
    :action => "update"
  })
  redirect '/announce'
end

get '/announce-hide-now/:a_id' do
  pin_auth!
  a = Announcement.get(params[:a_id])
  a.shown
  normalise_announcement_order
  send_to_sockets("announcements", {
    :for => "announcements",
    :action => "update"
  })
  redirect '/announce'
end

post '/announce-info-update' do
  result = false
  unless params[:announce_id].nil? && params[:state].nil?
    a = Announcement.get(params[:announce_id])
    unless a.nil? then
      state = ""
      if params[:state] == 'displayed' then
        a.shown
        state = "finished"
      end
      
      send_to_sockets("admin_update_ann", {
        :for => "admin",
        :action => "admin_update_ann",
        :announce_id => params[:announce_id],
        :state => state
      })
      
      result = true
    end
  end
  {:result => result}.to_json
end

# Diagnostics

get '/diagnostic' do
  pin_auth
  #puts request.env.inspect
  haml :diagnostic, :locals => {
    :scheme => request.env["rack.url_scheme"],
    :host => request.env["HTTP_HOST"],
    :ip => IPSocket.getaddress(Socket.gethostname),
    :port => request.env["SERVER_PORT"],
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

# Upload stuff

get '/upload' do
  pin_auth
  haml :upload
end

post '/upload' do
  pin_auth
  
  audio  = has_file(:audio_file, params)
  lyrics = has_file(:lyrics_file, params)
  image  = has_file(:image_file, params)
  
  #puts audio
  #puts lyrics
  #puts image
  
  unless (audio[:valid] && lyrics[:valid])
    puts 'no'
    redirect '/upload'
  end
  
  dirname = (audio[:name].split('.')[0] + (0...8).map{65.+(rand(25)).chr}.join).gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
  
  pub_base = "public/music/"
  
  uploads_dir = File.join(Dir.pwd, pub_base + "uploads")
  if (!File.exist?(uploads_dir))
    Dir.mkdir(uploads_dir, 0775)
  end
  
  song_dir = File.join(Dir.pwd, pub_base + "uploads", dirname)
  if (!File.exist?(song_dir))
    Dir.mkdir(song_dir, 0775)
  end
  short_song_dir = File.join("uploads", dirname) + '/'
  
  write_file(song_dir, audio)
  write_file(song_dir, lyrics)
  write_file(song_dir, image)
  
  s = Song.create(
    :title => params[:title],
    :artist => params[:artist],
    :album => params[:album],
    :origin_title => params[:origin_title],
    :origin_type => params[:origin_type],
    :origin_medium => params[:origin_medium],
    :genre => params[:genre],
    :language => params[:language],
    :karaoke => params[:karaoke],
    :source_dir => short_song_dir,
    :audio_file => audio[:name],
    :lyrics_file => lyrics[:name],
    :image_file => image[:name],
  )
  
  #puts s
  
  'Success! <br /> <a href="/upload">upload another song</a>'
end

# Queue control

get '/queue-control' do
  pin_auth
  haml :queue_control
end

post '/queue-control' do
  pin_auth
  HisaishiQueue.overwrite_queue(params[:queue_id])
  'Success! <br /> <a href="/queue">go to queue</a> <br /> <a href="/queue-control">go to queue control</a>'
end

# ##### HELPER FUNCTIONS

# Upload

def has_file(index, params)
  #puts params
  result = {
    :valid => false,
    :tmpfile => nil,
    :name => nil
  }
  test = (params[index] && (result[:tmpfile] = params[index][:tempfile]) && (result[:name] = params[index][:filename]))
  #puts test
  result[:valid] = !test.nil? && (test == params[index][:filename])
  return result
end

def write_file(song_dir, result)
  if (result[:valid])
    FileUtils.cp(result[:tmpfile].path, File.join(song_dir, result[:name]))
    #while blk = result[:tmpfile].read(65536)
    #  File.open(File.join(song_dir, result[:name]), "wb") { |f| f.write(result[:tmpfile].read) }
    #end
  end
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
  queue = HisaishiQueue.all(:order => [:queue_order.asc])
  queue.each do |q|
    s = Song.get(q.song_id)
    unless song_list.has_key? s.id then
      song_list[s.id] = s.player_data
    end
  end

  {
    :songs => song_list,
    :queue => queue
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


