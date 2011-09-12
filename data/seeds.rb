# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed

require 'csv'
require 'pp'

seeds_path = File.dirname(__FILE__) + "/seeds.csv"

CSV.foreach(seeds_path, :headers => :first_row) do |row|
  song = Song.new

  # Use the column names to set the fields.
  row.each do |field,value|
    song.send "#{field}=", value
  end

  song.save!
end
