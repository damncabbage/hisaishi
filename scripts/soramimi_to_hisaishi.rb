#!/usr/bin/env ruby
#
# Takes a Soramimi Karaoke songs directory and shuffles it around into the
# structure we use for hisaishi. It also dumps a seeds.csv file out into the
# root of the new directory for use with rake db:seed
#
# Usage:
#   ./soramimi_to_hisaish.rb /path/to/soramimi/Songs [/new/path/for/converted/songs]
#

require 'pp'

class HisaishiSong
  attr_accessor :title
  attr_accessor :artist
  attr_accessor :album
  attr_accessor :series
  attr_accessor :genre
  attr_accessor :language
  attr_accessor :karaoke
  attr_accessor :source_dir
  attr_accessor :audio_file
  attr_accessor :lyrics_file
  attr_accessor :image_file

  def lyrics_file
    title + ".txt" # TODO
  end

  def audio_file
    title + ".mp3" # TODO
  end

  class << self
    def to_csv(collection)
      result = ""
      collection.each do |song|
        result << song.title + "\n"
      end
      result
    end
  end
end

class SoramimiSong
  attr_accessor :audio_file

  def initialize(audio_file)
    self.audio_file = audio_file
  end

  def lyrics_file
    audio_file.sub(/.mp3$/, '.txt')
  end
  def title
    "Dummy"
  end
  def anime
    "TODO: Return if [foobar]"   
  end
  def artist
    "TODO: Return unless [foobar]"
  end
  def language
    "TODO: Return English unless /Songs/English/..."
  end
end


def print_usage
  puts "Usage: #{__FILE__} /path/to/soramimi/Songs [/new/path/for/converted/songs]"
end

def normalise_directory(path)
  unless path && File.directory?(path)
    raise "'#{path}' does not exist!"
  end
  File.realdirpath(path)
end

if ARGV.length != 2
  print_usage
  exit 1
end

source_path = normalise_directory(ARGV[0])
target_path = normalise_directory(ARGV[1])

songs = []
file_ops = []

Dir[File.join(source_path, "**", "*.mp3")].each do |sora_audio_file|
  sora_song = SoramimiSong.new(sora_audio_file)

  new_song = HisaishiSong.new
  new_song.title = sora_song.title

  file_ops << [sora_song.audio_file,  File.join(target_path, new_song.audio_file)] 
  file_ops << [sora_song.lyrics_file, File.join(target_path, new_song.lyrics_file)] 

  songs << new_song
end

file_ops.each do |op|
  from, to = op[0], op[1]
  puts "Copying from '#{from}' to '#{to}'..." # TODO: Use STDERR for reporting.
  # TODO
end

puts HisaishiSong.to_csv(songs)
