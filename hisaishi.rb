require 'rubygems'
require 'sinatra'
require 'sinatra/jsonp'
require 'cgi'

# Pulls in settings and required gems.
require File.expand_path('environment.rb', File.dirname(__FILE__))

# Base hisaishi functionality

use Rack::Session::Cookie

# HACK: Disable CSRF, add shim.
#apply_csrf_protection
def csrf_tag(*); end
def csrf_token(*); end


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

  puts song = Song.get(params[:song_id])
  puts song.vote(params[:vote], params[:reasons], session)
  puts params.inspect
  
  halt 200
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
    # HACK: Manually-created accounts, formatted as "user=
    accounts = {}
    accounts = CGI.parse(ENV['MANUAL_ACCOUNTS']) if ENV['MANUAL_ACCOUNTS']
    if accounts[params[:username]] && accounts[params[:username]] == [params[:password]]
      session[:username] = params[:username]
    else

      # Basecamp
      Basecamp.establish_connection! host, params[:username], params[:password], true
      token = Basecamp.get_token
      session[:username] = params[:username] unless token.nil?

    end
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

get '/queue.jsonp' do
  queue = HisaishiQueue.all
  JSONP queue
end

get '/queue/:song_id' do
  authenticate!

  song = Song.get(params[:song_id])
  haml :enqueue, :locals => { :song_id => song.id, :song_title => song.title }
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

# Helper functions

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
