class Vote
  include DataMapper::Resource
  property :vote_id,    Serial
  property :user,      String
  property :vote,      Enum[ :yes, :no, :dunno ], :default => :yes
  property :song_id,    Integer
  
  has n, :reasons
end