# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed¥.

require 'csv'

first = true

CSV.foreach(File.dirname(__FILE__) + "/seeds.csv") do |row|
  unless first
    song = Song.new
    song.title =  row[0]
    song.artist = row[1]
    song.album = row[2]
    song.anime = row[3]
    song.genre = row[4]
    song.language = row[5]
    song.karaoke = row[6]
    song.source_dir = row[7]
    song.audio_file = row[8]
    song.lyrics_file = row[9]
    song.image_file = row[10]
    song.save!
  end
  
  first = false
end