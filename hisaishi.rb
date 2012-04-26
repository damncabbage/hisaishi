require 'rubygems'
require 'sinatra'
require 'sinatra/jsonp'

# Pulls in settings and required gems.
require File.expand_path('environment.rb', File.dirname(__FILE__))

# Base hisaishi functionality

use Rack::Session::Cookie

apply_csrf_protection

get '/' do
  authenticate
  
  song = rand_song

  if song
    haml :song, :locals => { :song_json => song.json, :user => session[:username] }
  else
    haml :no_song
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

# Browser

get '/browse' do
  haml :browser
end

# Queue

get '/queue' do
  authenticate!
  haml :queue, :locals => queue_songs
end

get '/queue.jsonp' do
  authenticate!
  out = queue_songs
  JSONP out
end

get '/search' do
  haml :search, :locals => {
  	:songs => Song.all,
  	:authed => is_logged_in
  }
end

get '/add/:song_id' do
  song = Song.get(params[:song_id])
  haml :queue_song, :locals => {
  	:song => song
  }
end

post '/add-submit' do
  song = Song.get(params[:song_id])
  
  last_q = last_song_by_requester(params[:requester])
  diff = nil
  if !last_q.nil? then
    diff = Time.now - last_q.created_at
  end
  
  if !is_logged_in and !last_q.nil? and diff.round <= 300 then
    haml :queue_song_fail_limit, :locals => {
      :requester => params[:requester],
  	  :song => song,
  	  :diff => diff.distance_of_time_in_words
    }
  else
    new_queue = song.enqueue(params[:requester])
    
    haml :queue_song_ok, :locals => {
  	  :song => song, 
  	  :new_queue => new_queue,
      :authed => is_logged_in
    }
  end
end

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
	pin_auth!
	
	anns = Announcement.all(:order => [ :ann_order.asc ])
	haml :announcements, :locals => {
		:anns => anns
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
      :ann_order => Announcement.all.length
    )
    redirect '/announce'
end

# PIN auth screen

get '/lock-screen' do
  haml :lock_screen
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
    return (session[:username] = 'guest')
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
  session[:admin_pin] == settings.admin_pin
end

# DB Helper

def queue_songs
	song_list = {}
	HisaishiQueue.all.each do |q|
		s = Song.get(q.song_id)
		song_list[s.id] = s
	end
	
	{
		:songs => song_list,
		:queue => HisaishiQueue.all
	}
end

def last_song_by_requester(requester)
	HisaishiQueue.first(
	  :requester => requester, 
	  :order => [ :created_at.desc ]
	)
end

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
