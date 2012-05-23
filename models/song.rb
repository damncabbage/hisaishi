require 'mp3info'
require 'open-uri'

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
  
  def self.search(str)
  	str = '%' + str.downcase + '%'
    Song.all(:conditions => ['LOWER(title) LIKE ?', str]) + 
    Song.all(:conditions => ['LOWER(artist) LIKE ?', str]) + 
    Song.all(:conditions => ['LOWER(album) LIKE ?', str]) + 
    Song.all(:conditions => ['LOWER(origin_title) LIKE ?', str])
  end
  
  def path_base
    return settings.files + source_dir
  end
  
  def path
    return self.path_base + audio_file
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
      :folder  => self.path_base,
      :audio   => audio_file,
      :lyrics  => lyrics_file,
      :cover   => image_file
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
    begin
      open(self.path) do |data|  
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
end
