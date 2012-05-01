class Announcement
  include DataMapper::Resource
  property :id,      		Serial
  property :text, 	    	Text
  property :displayed,		Boolean, 	:default => false
  property :ann_order, 		Integer
  
  def json
    a_data = []
    a_data << {
      :id    		=> id,
      :text   		=> text,
      :displayed  	=> displayed,
      :ann_order	=> ann_order
    }
    return a_data.to_json
  end 
  
  def show_now
  	self.update(
    	:displayed => false, 
    	:ann_order => -1
  	)
  end
  
  def shown
	self.update(
    	:displayed => true
  	)
  end
end
