class HisaishiQueue
  include DataMapper::Resource
  property :id,      		Serial
  property :song_id,     	Integer
  property :time,     		Integer
  property :requester,     	Text
  property :queue_order,    Integer
  property :play_state,  	Enum[ :queued, :playing, :finished ], :default => :queued
  property :created_at,		DateTime
  
  def json
    q_data = []
    q_data << {
      :id    		=> id,
      :song_id   	=> song_id,
      :time  		=> time,
      :requester   	=> requester,
      :queue_order	=> queue_order,
      :play_state   => play_state,
      :created_at	=> created_at
    }
    return q_data.to_json
  end 
end
