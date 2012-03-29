class Queue
  include DataMapper::Resource
  property :id,      Serial
  property :song_id,     Integer
  property :time,     Integer
  property :requester,     Text
  
  def json
    q_data = []
    q_data << {
      :id    		=> id,
      :song_id   	=> song_id,
      :time  		=> time,
      :requester   	=> requester
    }
    return q_data.to_json
  end 
end
