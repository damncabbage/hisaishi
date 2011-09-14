class Reason
  include DataMapper::Resource
  property :id,    Serial
  property :type,      Enum[ :none, :wrong, :mistimed, :misspelt, :details ], :default => :none
  property :comment,  Text
  
  belongs_to :vote
end