class Vote
  include DataMapper::Resource
  property :vote_id,    Serial
  property :user,      String
  property :vote,      Enum[ :yes, :no, :unknown ], :default => :unknown
  property :song_id,    Integer
  
  has n, :reasons
end