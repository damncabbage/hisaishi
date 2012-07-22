class Song < ActiveRecord::Base

  # Translates the 'karaoke' enum back and forth
  # between true/false/nil and 1/2/3 (what DataMapper's
  # ENUM property deals out)
  include Song::EnumCompatibility

  # Associations
  has_many :queue_items

  # Class Methods
  class << self
    def search(text)
      terms = "%#{text}%"
      self.class.where('
        LOWER(title) LIKE ?
        OR LOWER(artist) LIKE ?
        OR LOWER(album) LIKE ?
        OR LOWER(origin_title) LIKE ?
      ', terms, terms, terms, terms)
    end

    def clean_string(str)
      return nil unless str
      str.gsub('[', '%5B').gsub(']', '%5D').gsub('+', '%2B')
    end
  end

  # Instance Methods
  def audio_path
    (path_base + audio_file) if audio_file
  end
  alias_method :path, :audio_path

  def image_path
    (path_base + image_file) if image_file
  end

  def lyrics_path
    (path_base + lyrics_file) if lyrics_file
  end

  def lyrics?
    # TODO: Cache this in song row?
    return false unless lyrics_file

    # TODO: Refactor
    path = URI.escape(path_base + lyrics_file).gsub('[', '%5B').gsub(']', '%5D').gsub('+', '%2B')
    puts path
    data = nil
    file = StringIO.new
    begin
      open(path) do |data|  
        file.write data.read(4096)
      end
    rescue StandardError => bang
      puts "Error: #{bang}"
    end
    puts file.length
    return file.length > 50 # Anything less isn't a real song. :[
  end

  def enqueue(requester)
    time = self.length
    if length == 0 then
      data = audio_details
      time = data.length.ceil if data && data.length
    end
    queue_item = QueueItem.create(
      :requester 	=> requester,
      :song_id 		=> id,
      :time 		=> time,
      :position => QueueItem.count
    )
    queue_item
  end

  def audio_details
    return @audio_details if @audio_details

    temp_mp3 = StringIO.new
    path = self.class.clean_string(URI.escape(path))
    begin
      open(path) do |data|  
        temp_mp3.write data.read(4096)
      end
      temp_mp3.rewind
      Mp3Info.open(temp_mp3) do |mp3info|
        @audio_details = mp3info
      end
    rescue StandardError => bang
      puts "Error: #{bang}"
    end
    @audio_details
  end

  def local_audio_path
    "public/music/#{source_dir}#{audio_file}" if settings.files_are_local && audio_file
  end

  def local_lyrics_path
    "public/music/#{source_dir}#{lyrics_file}" if settings.files_are_local && lyrics_file
  end

  def local_image_path
    "public/music/#{source_dir}#{image_file}" if settings.files_are_local && image_file
  end

  protected

    def path_base
      settings.files + source_dir
    end

end
