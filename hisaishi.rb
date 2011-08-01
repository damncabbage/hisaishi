# hisaishi.rb
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'data_mapper'
require 'dm-migrations'
require 'dm-ar-finders'
require 'haml'

set :public, Proc.new { File.join(root, "public") }

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/data/hisaishi.sqlite")

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

DataMapper.auto_migrate! unless Song.storage_exists?

get '/' do
	song = rand_song()
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
		haml :song, :locals => {:song => song, :song_json => song_json}
	else
		haml :no_song
	end
end

put '/song/:song_id/yes' do
	song = song_by_id(params[:song_id])
	song.update(:yes => song.yes + 1)
	'+1 yes'
end

put '/song/:song_id/no' do
	song = song_by_id(params[:song_id])
	song.update(:no => song.no + 1)
	'+1 no'
end

get '/list-songs' do
	songs = Song.all
	haml :song_list, :locals => {:songs => songs}
end

def song_by_id(id)
	return Song.get(id)
end

def rand_song()
	return Song.find_by_sql("SELECT * FROM songs ORDER BY RANDOM() LIMIT 1;")
end
