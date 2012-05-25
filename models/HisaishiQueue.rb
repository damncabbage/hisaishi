class HisaishiQueue
  include DataMapper::Resource
  property :id,      		Serial
  property :song_id,     	Integer
  property :time,     		Integer
  property :requester,     	Text
  property :queue_order,    Integer
  property :play_state,  	Enum[ :queued, :ready, :playing, :paused, :finished ], :default => :queued
  property :created_at,		DateTime
  
  def self.normalise_all
  	i = 0
	HisaishiQueue.all(:order => [:queue_order.asc, :play_state.asc]).each do |q|
		q.update(:queue_order => i)
		i += 1
	end
  end
  
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
  
  def stop
  	self.update(:play_state => :finished)
  end
  
  def prep
  	self.update(:play_state => :queued)
  end
  
  def pause
  	self.update(:play_state => :paused)
  end
  
  def unpause
  	self.update(:play_state => :playing)
  end
  
  # Forward playback head to this song
  def play_now
    playing = HisaishiQueue.all(:play_state => :ready) + 
    	HisaishiQueue.all(:play_state => :playing) + 
    	HisaishiQueue.all(:play_state => :paused)
    
    playing.each do |q|
      if q.queue_order < queue_order
        q.stop
      else
        q.prep
      end
    end
    HisaishiQueue.all(:queue_order.gt => queue_order).each do |q|
      q.prep
    end
    
    HisaishiQueue.get(id).update(:play_state => :ready)
  end
  
  # Move this song before the currently played song
  def play_next
    q_ord = -1
    
    q = HisaishiQueue.all(:play_state => :ready) | 
    	HisaishiQueue.all(:play_state => :playing) | 
    	HisaishiQueue.all(:play_state => :paused)
    
    unless q.length == 0
    	q_ord = q[0].queue_order + 1
    end
    
    HisaishiQueue.all(:queue_order.gte => q_ord).each do |q|
      q.update(:queue_order => q.queue_order + 1)
    end
    
  	self.update(:play_state => :queued, :queue_order => q_ord)
  	HisaishiQueue.normalise_all
  end
  
  # Move this song to end of queue
  def play_last
  	self.update(
  		:play_state => :queued, 
  		:queue_order => HisaishiQueue.all.length
  	)
  	HisaishiQueue.normalise_all
  end
  
  # Play the next song
  def play_next_now
  	q = HisaishiQueue.first(:queue_order.gt => queue_order, :order => [:queue_order.asc, :play_state.asc])
  	q.play_now
  end
end
