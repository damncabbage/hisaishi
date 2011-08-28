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
    song.source_dir = row[3]
    song.audio_file = row[4]
    song.lyrics_file = row[5]
    song.image_file = row[6]
    song.save!
  end
  
  first = false
end