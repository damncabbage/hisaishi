class Vote
  include DataMapper::Resource
  property :vote_id,    Serial
  property :user,      String
  property :song_id,    Integer
  property :vote,      Integer
  property :comment,  String
end