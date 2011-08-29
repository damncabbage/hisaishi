class Song
  include DataMapper::Resource
  property :id,      Serial
  property :title,     String
  property :artist,     String
  property :album,     String
  property :source_dir,   String
  property :audio_file,   String
  property :lyrics_file,   String
  property :image_file,   String
  property :yes,      Integer,   :default => 0
  property :no,      Integer,   :default => 0
  
  def json
    song_data = []
    song_data << {
      :id    => id,
      :title   => title,
      :artist  => artist,
      :album   => album,
      :folder  => settings.files + source_dir,
      :lyrics  => lyrics_file,
      :audio   => audio_file,
      :cover   => image_file
    }
    return song_data.to_json
  end
  
  def vote(is_yes, session)
    vote_int = 0
    if is_yes
      vote_int = 1
      self.yes = self.yes + 1
    else
      self.no = self.no + 1
    end
    
    self.save!
    
    vote = Vote.create(
      :user => session[:username],
      :song_id => self.id,
      :vote => vote_int
    )
  end  
end