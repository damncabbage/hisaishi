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
    displayed = false
    ann_order = Announcement.all.length
  	self.save!
  end
  
  def shown
    displayed = true
  end
end
