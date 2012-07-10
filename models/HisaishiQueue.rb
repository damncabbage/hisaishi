class HisaishiQueue
  include DataMapper::Resource
  property :id,      		Serial
  property :song_id,     	Integer
  property :time,     		Integer
  property :requester,     	Text
  property :queue_order,    Integer
  property :play_state,  	Enum[ :queued, :ready, :playing, :paused, :stopped, :finished ], :default => :queued
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
  
  def mass_queue_cleanup(id)
    current = HisaishiQueue.get(id)
    (HisaishiQueue.all(:queue_order.lt => self.queue_order) - current).update(:play_state => :finished)
    (HisaishiQueue.all(:queue_order.gt => self.queue_order) - current).update(:play_state => :queued)
    HisaishiQueue.normalise_all
  end
  
  def stop
  	self.update(:play_state => :stopped)
  	mass_queue_cleanup(self.id)
  end
  
  def prep
  	self.update(:play_state => :queued)
  	mass_queue_cleanup(self.id)
  end
  
  def pause
  	self.update(:play_state => :paused)
  	mass_queue_cleanup(self.id)
  end
  
  def unpause
  	self.update(:play_state => :playing)
  	mass_queue_cleanup(self.id)
  end
  
  # Forward playback head to this song
  def play_now
    playing = HisaishiQueue.all(:play_state => :ready) + 
    	HisaishiQueue.all(:play_state => :playing) + 
    	HisaishiQueue.all(:play_state => :paused) + 
    	HisaishiQueue.all(:play_state => :stopped)
    
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
    mass_queue_cleanup(id)
  end
  
  # Move this song before the currently played song
  def play_next
    q_ord = -1
    
    q = HisaishiQueue.all(:play_state => :ready) | 
    	HisaishiQueue.all(:play_state => :playing) | 
    	HisaishiQueue.all(:play_state => :paused) | 
    	HisaishiQueue.all(:play_state => :stopped)
    
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
  
  def self.predefined_queues
    {
      "single_heat" => [
        {:song_id => 524, :requester => 'Shanee Conran'}, 
        {:song_id => 601, :requester => 'Clarissa Lin'}, 
        {:song_id => 602, :requester => 'Corina Alexe (aka Corinne Procycon)'}, 
        {:song_id => 603, :requester => 'Susan'}, 
        {:song_id => 604, :requester => 'Phoebe Sim'}, 
        {:song_id => 605, :requester => 'Alex Ngai'}, 
        {:song_id => 606, :requester => 'Chantel Simeoni'}, 
        {:song_id => 607, :requester => 'Lynneal Santos (nime)'}, 
        {:song_id => 608, :requester => 'Xena'}, 
        {:song_id => 609, :requester => 'Vivienne'}, 
        {:song_id => 610, :requester => 'Mel'}, 
        {:song_id => 611, :requester => 'Gabriel Seah Hian Ong'}, 
        {:song_id => 612, :requester => 'Jane Soo'}, 
        {:song_id => 613, :requester => 'Belinda Yuqi Ding'}, 
        {:song_id => 614, :requester => 'Jennifer Akitsuki'}, 
        {:song_id => 383, :requester => 'Aarti Mahajan'}, 
        {:song_id => 615, :requester => 'Mai Uchino'}, 
        {:song_id => 134, :requester => 'Nadya Shturman'}, 
        {:song_id => 524, :requester => 'Karen Algeo'}, 
        {:song_id => 616, :requester => 'Kaylee Chidgey'}, 
        {:song_id => 617, :requester => 'Sophia Kim'}, 
        {:song_id => 618, :requester => 'Crystal Bai'}, 
        {:song_id => 619, :requester => 'Annie Lam'}, 
        {:song_id => 620, :requester => 'Ben Pushka'}, 
      ],
      "duet_heat" => [
        {:song_id => 370, :requester => 'Emily Shen'}, 
        {:song_id => 621, :requester => 'Corina Alexe (aka Corinne Procycon) n Minh Procycon'}, 
        {:song_id => 622, :requester => 'Andrea n Brenda Lo'}, 
        {:song_id => 623, :requester => 'Elizabeth n Soo Yeun Melissa Lim'}, 
        {:song_id => 624, :requester => 'Justine Jiang n Susan Lee'}, 
        {:song_id => 625, :requester => 'Gabriel n Lisa'},         
        {:song_id => 626, :requester => 'Emi Stuart n Mari Stuart'}, 
        {:song_id => 627, :requester => 'Elsa Hon n Amy'}, 
        # sorairo days, shoko nakagawa, Belinda Yuqi Ding n Michael Chan
        # missing song, Annie Lam n Mai Uchino
        {:song_id => 628, :requester => 'Tranh Tran Thein Le n Vi Tuong Nguyen'},
        {:song_id => 629, :requester => 'Derrasanc n Genn'},
      ],
      "single_final" => [
      ],
      "duet_final" => [
      ]
    }
  end
  
  # Nukes the queue and 
  def self.overwrite_queue(queue_id)
    HisaishiQueue.all.destroy
    queue_base = HisaishiQueue.predefined_queues[queue_id]
    unless queue_base.nil?
      queue_base.each do |i|
        song = Song.get(i[:song_id])
        unless song.nil?
          new_queue = song.enqueue(i[:requester])
        end
      end
    end
  end
  
end
