class Song
  include DataMapper::Resource
  property :id,      Serial
  property :title,     String
  property :artist,     String
  property :album,     String
  property :origin_title,    String
  property :origin_type,    String
  property :origin_medium,    String
  property :genre,    String
  property :language, String
  property :karaoke,  Enum[ :true, :false, :unknown ], :default => :unknown
  property :source_dir,   String
  property :audio_file,   String
  property :lyrics_file,   String
  property :image_file,   String
  property :yes,      Integer,   :default => 0
  property :no,      Integer,   :default => 0
  property :unknown,      Integer,   :default => 0  
  
  def json
    song_data = []
    song_data << {
      :id    => id,
      :title   => title,
      :artist  => artist,
      :album   => album,
      :origin_title  => origin_title,
      :origin_type   => origin_type,
      :origin_medium => origin_medium,
      :genre    => genre,
      :language => language,
      :karaoke  => karaoke,
      :folder   => settings.files + source_dir,
      :lyrics   => lyrics_file,
      :audio    => audio_file,
      :cover    => image_file
    }
    return song_data.to_json
  end
  
  def vote(vote, comment, session)
    if vote == 'yes'
      vote_int = 1
      self.yes = self.yes + 1
    elsif vote == 'no'
      vote_int = 0
      self.no = self.no + 1
    elsif vote == 'unknown'
      vote_int = -1
      self.unknown = self.unknown + 1
    end
    
    self.save!
    
    vote = Vote.create(
      :user => session[:username],
      :song_id => self.id,
      :vote => vote_int,
      :comment => comment
    )
  end  
end
