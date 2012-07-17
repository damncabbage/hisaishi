require 'mp3info'
require 'open-uri'
require 'cgi'

class Song
  include DataMapper::Resource
  property :id,      Serial
  property :title,     Text
  property :artist,     Text
  property :album,     Text
  property :origin_title,    Text
  property :origin_type,    Text
  property :origin_medium,    Text
  property :genre,    Text
  property :language, Text
  property :karaoke,  Enum[ :true, :false, :unknown ], :default => :unknown
  property :source_dir,   Text
  property :audio_file,   Text
  property :lyrics_file,   Text
  property :image_file,   Text
  property :length,		Integer,   :default => 0
  property :yes,      Integer,   :default => 0
  property :no,      Integer,   :default => 0
  property :unknown,      Integer,   :default => 0  
  
  property :created_at, DateTime, :default => lambda{ |p,s| DateTime.now}
  property :updated_at, DateTime, :default => lambda{ |p,s| DateTime.now}
  
  before :save do
    updated_at = DateTime.now
  end
  
  def self.search(str)
  	str = '%' + str.downcase + '%'
    Song.all(:conditions => ['LOWER(title) LIKE ?', str]) + 
    Song.all(:conditions => ['LOWER(artist) LIKE ?', str]) + 
    Song.all(:conditions => ['LOWER(album) LIKE ?', str]) + 
    Song.all(:conditions => ['LOWER(origin_title) LIKE ?', str])
  end
  
  def self.clean_string(str)
    unless str.nil? then
      str.gsub('[', '%5B').gsub(']', '%5D').gsub('+', '%2B')
    end
  end
  
  def path_base
    return settings.files + source_dir
  end
  
  def audio_path
    if !audio_file.nil? then
      return self.path_base + audio_file
    else
      return nil
    end
  end
  
  alias_method :path, :audio_path
  
  def lyrics_path
    if !lyrics_file.nil? then
      return self.path_base + lyrics_file
    else
      return nil
    end
  end
  
  def image_path
    if !image_file.nil? then
      return self.path_base + image_file
    else
      return nil
    end
  end
  
  def lyrics_exists
    unless (!lyrics_file.nil?)
      return false
    end
    
    path = URI.escape(self.path_base + lyrics_file).gsub('[', '%5B').gsub(']', '%5D').gsub('+', '%2B')
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
  
  def player_data
    {
      :id    => id,
      :title   => title,
      :artist  => artist,
      :album   => album,
      :origin_title  => origin_title,
      :origin_medium   => origin_medium,
      :origin_type => origin_type,
      :genre => genre,
      :language => language,
      :karaoke => karaoke,
      #:folder  => Song.clean_string(self.path_base),
      #:audio   => Song.clean_string(audio_file),
      #:lyrics  => Song.clean_string(lyrics_file),
      #:cover   => Song.clean_string(image_file)
      
      :folder  => '/song/' + id.to_s,
      :audio   => '/audio.mp3',
      :lyrics  => '/lyrics.txt',
      :cover   => '/image',
    }
  end
  
  def json
    song_data = []
    song_data << self.player_data
    return song_data.to_json
  end
  
  def vote(vote, reasons, session)
    if vote == 'yes'
      self.yes = self.yes + 1
    elsif vote == 'no'
      self.no = self.no + 1
    elsif vote == 'unknown'
      self.unknown = self.unknown + 1
    end
    
    self.save!
    
    vote = Vote.create(
      :user => session[:username],
      :song_id => self.id,
      :vote => vote
    )
    
    if vote == 'no'
      reasons.each do |idx, reason|
        vote.reasons.create(
          :type => reason['type'],
          :comment => reason['comment']
        )
      end
    end
  end
  
  def enqueue(requester)
    time = self.length
    
    if time == 0 then
      data = self.get_data!
      if !data.nil? then
        time = data.length.ceil
      end
    end
    
    len = HisaishiQueue.all.length
    
    new_q = HisaishiQueue.new({
      :requester 	=> requester,
      :song_id 		=> self.id,
      :time 		=> time,
      :queue_order 	=> len
    })
    new_q.save
    new_q
  end
  
  def get_data!
  	data = nil
    mp3 = StringIO.new
    path = Song.clean_string(URI.escape(self.path))
    begin
      open(path) do |data|  
        mp3.write data.read(4096)
      end
      mp3.rewind
      Mp3Info.open(mp3) do |mp3info|
        data = mp3info
      end
    rescue StandardError => bang
      puts "Error: #{bang}"
    end
    return data
  end
  
  def local_audio_path
    if settings.files_local and !audio_file.nil? then
      'public/music/' + source_dir + audio_file
    else
      nil
    end
  end
  
  def local_lyrics_path
    if settings.files_local and !lyrics_file.nil? then
      'public/music/' + source_dir + lyrics_file
    else
      nil
    end
  end
  
  def local_image_path
    if settings.files_local and !image_file.nil? then
      'public/music/' + source_dir + image_file
    else
      nil
    end
  end
  
end
