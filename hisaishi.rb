# hisaishi.rb
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'data_mapper'
require 'dm-migrations'
require 'dm-ar-finders'
require 'haml'

Dir["#{File.dirname(__FILE__)}/vendor/{gems,plugins}/**/*.rb"].each { |f| load(f) }

enable :sessions
set :public, Proc.new { File.join(root, "public") }

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/data/hisaishi.sqlite")

class Song
	include DataMapper::Resource
	property :id,			Serial
	property :title, 		String
	property :artist, 		String
	property :album, 		String
	property :source_dir, 	String
	property :audio_file, 	String
	property :lyrics_file, 	String
	property :image_file, 	String
	property :yes,			Integer, 	:default => 0
	property :no,			Integer, 	:default => 0
end

class Vote
	include DataMapper::Resource
	property :vote_id,		Serial
	property :user,			String
	property :song_id,		Integer
	property :vote,			Integer
end

Song.auto_migrate! unless Song.storage_exists?
Vote.auto_migrate! unless Vote.storage_exists?

get '/' do
	unless is_logged_in
		redirect '/login'
	end
	song = rand_song
	if song.length > 0
		@song_data = []
		song.all.each do |s|
			@song_data << {
				:id		=> s.id,
				:title 	=> s.title,
				:artist	=> s.artist,
				:album 	=> s.album,
				:folder	=> s.source_dir,
				:lyrics	=> s.lyrics_file,
				:audio 	=> s.audio_file,
				:cover 	=> s.image_file
			}
		end
		song_json = @song_data.to_json
		haml :song, :locals => {
			:song => song, 
			:song_json => song_json,
			:user => session[:username]
		}
	else
		haml :no_song
	end
end

put '/song/:song_id/yes' do
	if is_logged_in
		vote_for_song(params[:song_id], true)
		'+1 yes'
	else
		halt 403, 'you are not logged in'
	end
end

put '/song/:song_id/no' do
	if is_logged_in
		vote_for_song(params[:song_id], false)
		'+1 no'
	else
		halt 403, 'you are not logged in'
	end
end

get '/list-songs' do
	if is_logged_in
		songs = Song.all
		haml :song_list, :locals => {:songs => songs}
	else
		redirect '/login'
	end
end

get '/login' do
	if is_logged_in
		redirect '/'
	else
		haml :login
	end
end

post '/login' do
	host = params[:host] + '.basecamphq.com'
	begin
		Basecamp.establish_connection! host, params[:username], params[:password], true
		token = Basecamp.get_token
		session[:username] = params[:username] unless token.nil?
	rescue ArgumentError
	end
	redir = '/login'
	if is_logged_in
		redir = '/'
	end
	redirect redir
end

get '/logout' do
	session[:username] = nil
	redirect '/login'
end

def is_logged_in
	if session.has_key?(:username)
		if x ||= session[:username]
			return true
		else
			return false
		end
	else
		return false
	end
end

def song_by_id(id)
	return Song.get(id)
end

def rand_song
	return Song.find_by_sql(
		'SELECT * FROM songs s ' + 
		'LEFT JOIN votes v ON (v.song_id = s.id AND v.user="' + session[:username] + '") ' + 
		'WHERE v.vote_id IS NULL ' + 
		'AND s.no < 1 AND s.yes < 3 ' + 
		'ORDER BY RANDOM() LIMIT 1;'
	)
end

def vote_for_song(id, is_yes)
	song = song_by_id(id)
	vote_int = 0
	if is_yes
		vote_int = 1
		song.update(:yes => song.yes + 1)
	else
		song.update(:no => song.no + 1)
	end
	vote = Vote.create(
		:user => session[:username],
		:song_id => song.id,
		:vote => vote_int
	)
end
