require 'rubygems'
require 'sinatra'
require File.join(File.dirname(__FILE__), 'environment')

get '/' do
  redirect '/login' unless is_logged_in
  
  song = rand_song

  if song
    haml :song, :locals => { :song_json => song.json, :user => session[:username] }
  else
    haml :no_song
  end
end

post '/song/:song_id/vote' do
  authenticate
  
  song = song_by_id(params[:song_id])
  song.vote(params[:vote], params[:comment], session)
end

get '/list-songs' do
  authenticate

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
    redirect '/'
  else
    redirect '/login'
  end
end

get '/logout' do
  session[:username] = nil
  redirect '/login'
end

get '/proxy' do
  url = params[:url]
  puts 'The URL was: ' + url
  open(URI.encode(url.gsub('[', '%5B').gsub(']', '%5D'))).read
end

def authenticate
  halt(403, 'You are not logged in.') unless is_logged_in
end

def is_logged_in
  if session.has_key?(:username)
    return (x ||= session[:username]) ? true : false
  end
  
  return false
end

def song_by_id(id)
  return Song.get(id)
end

def rand_song
  songs = Song.find_by_sql(
    #'SELECT * FROM songs s ' + 
    #'LEFT JOIN votes v ON (v.song_id = s.id AND v.user="' + session[:username] + '") ' + 
    #'WHERE v.vote_id IS NULL ' + 
    #'AND s.no < 1 AND s.yes < 3 ' + 
    #'ORDER BY RANDOM() LIMIT 1;'
    
    'SELECT * FROM songs ' + 
    'WHERE "id" NOT IN (' +
    '  SELECT "song_id" FROM votes ' + 
    '  WHERE "user" = \'' + session[:username] + '\'' + 
    '  GROUP BY "song_id" HAVING COUNT(*) > 0 ' + 
    ') ' + 
    'AND "no" < 1 AND "yes" < 3 ' + 
    'ORDER BY RANDOM();'
  )
  
  if songs.length > 0
    return songs.pop
  else
    return false
  end
end
