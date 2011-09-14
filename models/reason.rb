class Reason
  include DataMapper::Resource
  property :id,    Serial
  property :type,      Enum[ :none, :wrong, :mistimed, :misspelt ], :default => :none
  property :comment,  String
  
  belongs_to :vote
end