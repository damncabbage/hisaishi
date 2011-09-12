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

# TODO: Move this off to lib/hisaishi/import/
module Hisaishi
  module Import

    class HisaishiSong
      attr_accessor :base_dir

      attr_accessor :title
      attr_accessor :artist
      attr_accessor :album
      attr_accessor :origin_title
      attr_accessor :origin_type
      attr_accessor :origin_medium
      attr_accessor :genre
      attr_accessor :language
      attr_accessor :karaoke
      attr_accessor :source_dir
      attr_accessor :audio_file
      attr_accessor :lyrics_file
      attr_accessor :image_file

      def initialize(base_dir)
        self.base_dir = base_dir
      end

      # eg. "/jp/Bleach/FLOW!/Bleach - FLOW! (Karaoke).mp3"
      def file_path_template(ext)
        origin_or_artist = (origin_title ? origin_title : artist)
        karaoke_suffix = " (Karaoke)" if karaoke
        File.join(language, origin_or_artist, title, "#{origin_or_artist} - #{title}#{karaoke_suffix}.#{ext}")
      end

      def lyrics_file
        file_path_template('txt')
      end

      def audio_file
        file_path_template('mp3')
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
      attr_accessor :base_dir
      attr_accessor :audio_file

      def initialize(base_dir, audio_file)
        self.base_dir = base_dir
        self.audio_file = audio_file
      end

      def lyrics_file
        audio_file.sub(/.mp3$/, '.txt')
      end

      def title
        matches = stem.match(/_([^_]+)$/)
        if matches
          # Before returning, remove "[Foobar Baz]", "(Karaoke)",
          # "(Sakamoto ArtistName)" and "Artist Name - " because
          # some song titles are stuffed and/or have other things
          # mixed in.
          matches[1].sub(/\[[^\]]+\]/, '')
                    .sub(/\([^)]+\)/i, '')
                    .sub(/^[^-]+- /i, '')
                    .strip
        end
      end

      def series
        matches = stem.match(/\[([^\]]+)\]/)
        matches[1] if matches
      end

      def karaoke
        case stem
        when /\(Karaoke\)/i            then true
        when /\(Unofficial Karaoke\)/i then true

        when /\(Vocal\)/i    then false
        when /^Vocal_/i      then false
        when /- Vocal/i      then false
        when /\(Original\)/i then false

        # Return true by default for the moment; most songs
        # don't mention if they are karaoke or not.
        # Most songs that don't are generally karaoke.
        else true
        end
      end

      def artist
        artist = nil

        # Got a series? The artist will not be in the title (most of the time)
        # Check just in case; sometimes artists are put in as "Song Title (Artist Name)"
        #
        # eg. "[Bleach]_FLOW! (Awesome Guy)" will have:
        #   - "Bleach" picked up by self.series
        #   - "FLOW!" picked up by self.title
        #   - "Awesome Guy" picked up by the code below
        stem.scan(/\(([^)]+)\)/i).each do |m|
          artist = m[0] unless m[0].match(/(Karaoke|Original)/)
        end
        return artist if artist

        # Second attempt "Artist Name - Song Title"
        matches = stem.match(/^[^_]+_(?:\[[^\]]+\] )?([^-]+)-/i)
        return matches[1].strip if matches
        
        # Okay, neither worked, just bail if we've already got the series info.
        return nil if series

        # Otherwise, it's the bit before the last underscore.
        matches = stem.match(/^(.+)_[^_]+$/) # Capture up to the last _ in the string.
        matches[1].strip if matches
      end

      def language
        # Return Japanese unless the file path starts with "English/..."
        # (We suck, this is a hack, etc.)
        matches = audio_file.match(/^English/i)
        matches ? "en" : "jp"
      end

      protected

      # Grab the filename without the extension, eg. "[Bleach]_FLOW! (Awesome Guy)"
      def stem
        @stem ||= File.basename(audio_file).sub(/\.mp3$/, '')
      end
    end

    class CopyOperation
      attr_accessor :src, :dest
      def initialize(src, dest)
        self.src = src
        self.dest = dest
        @utils = FileUtils::DryRun
      end
      def to_s
        "Copying '#{src}' => '#{dest}'"
      end
      def run
        @utils.mkdir_p(File.dirname(dest))
        @utils.cp(src, dest)
      end
    end

  end
end


# The actual import script
include Hisaishi::Import

def print_usage
  puts "Usage: #{__FILE__} /path/to/soramimi/Songs /new/path/for/converted/songs"
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

Dir[File.join(source_path, "**", "*.mp3")].each do |sora_audio_file_absolute|
  sora_audio_file = sora_audio_file_absolute.sub(source_path + File::SEPARATOR, '')

  sora_song = SoramimiSong.new(source_path, sora_audio_file)

  new_song = HisaishiSong.new(target_path)

  new_song.title        = sora_song.title
  new_song.artist       = sora_song.artist
  new_song.origin_title = sora_song.series
  new_song.origin_type  = 'anime' if (sora_song.series && sora_song.language == 'jp') # Hey, it's a hack.
  new_song.language     = sora_song.language
  new_song.karaoke      = sora_song.karaoke

  file_ops << CopyOperation.new(File.join(source_path, sora_song.audio_file),  File.join(target_path, new_song.audio_file))
  file_ops << CopyOperation.new(File.join(source_path, sora_song.lyrics_file), File.join(target_path, new_song.lyrics_file))

  songs << new_song
end

file_ops.each do |op|
  puts op
  op.run
end

#puts HisaishiSong.to_csv(songs)
