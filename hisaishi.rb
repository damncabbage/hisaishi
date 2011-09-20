require 'rubygems'
require 'sinatra'

# Pulls in settings and required gems.
require File.expand_path('environment.rb', File.dirname(__FILE__))


get '/' do
  authenticate true
  
  song = rand_song

  if song
    haml :song, :locals => { :song_json => song.json, :user => session[:username] }
  else
    haml :no_song
  end
end

get '/song/:song_id' do
  authenticate true

  song = Song.get(params[:song_id])

  if song
    haml :song, :locals => { :song_json => song.json, :user => session[:username] }
  else
    haml :no_song
  end
end

post '/song/:song_id/vote' do
  authenticate false
  
  song = Song.get(params[:song_id])
  song.vote(params[:vote], params[:reasons], session)
  
  return true
end

get '/songs/list' do
  authenticate true

  songs = Song.all
  haml :song_list, :locals => {:songs => songs}
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
    redirect session.delete(:intended_url) || '/'
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

def authenticate(offer_login)
  session[:intended_url] = request.referer
  
  if offer_login
    redirect '/login' unless is_logged_in    
  else  
    halt(403, 'You are not logged in.') unless is_logged_in
  end
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
