require 'rubygems'
require 'sinatra/base'
require 'sinatra/jsonp'
require 'natural_time'
require 'socket'

module Sinatra
  module HisaishiAnnouncements
    
    module Helpers
      def normalise_announcement_order
      	ids = []
      	Announcement.all(:order => [:ann_order.asc]).each do |a|
      		ids << a.id
      	end
      	reorder_announcements(ids)
      end

      def reorder_announcements(announce_ids)
      	i = 0
      	announce_ids.each do |a_id|
      		a = Announcement.get(a_id);
      		a.update(:ann_order => i)
      		i += 1
      	end
      end
    end
    
    def self.registered(app)
      	app.helpers HisaishiAnnouncements::Helpers
      
		app.get '/announce' do
			pin_auth
	
			anns = Announcement.all(:order => [ :ann_order.asc ])
			haml :announce, :locals => {
				:announce => anns,
		  		:authed => has_admin_pin
			}
		end

		app.get '/announce.jsonp' do
			pin_auth!
	
			anns = Announcement.all(:order => [ :ann_order.asc ])
			JSONP anns
		end

		app.post '/announce' do
			text = params[:text]
			new_ann = Announcement.create(
		      	:text => text,
		      	:ann_order => Announcement.all.length,
		  		:authed => has_admin_pin
		    )
		    redirect '/announce'
		end

		app.get '/announce-add' do
		  pin_auth!
		  haml :announce_add
		end

		app.post '/announce-add-process' do
		  pin_auth!
  
		  a = Announcement.create(
		    :text   		=> params[:text],
		    :ann_order 		=> Announcement.all.length,
		    :displayed		=> params[:show_now] != '1'
		  )
  
		  normalise_announcement_order
		  
		  redirect '/announce'
		end

		app.get '/announce-delete/:a_id' do
		  pin_auth!
		  a = Announcement.get(params[:a_id])
		  haml :announce_delete_confirm, :locals => {
		  	:ann => a
		  }
		end

		app.post '/announce-delete-process' do
		  pin_auth!
		  a = Announcement.get(params[:a_id])
		  a.destroy
		  normalise_announcement_order
		  redirect '/announce'
		end

		app.post '/announce-reorder' do
		  pin_auth!
		  unless params[:announce].nil?
		    reorder_announcements(params[:announce])
		  end
		end

		app.get '/announce-show-now/:a_id' do
		  pin_auth!
		  a = Announcement.get(params[:a_id])
		  a.show_now
		  normalise_announcement_order
		  redirect '/announce'
		end

		app.get '/announce-hide-now/:a_id' do
		  pin_auth!
		  a = Announcement.get(params[:a_id])
		  a.shown
		  normalise_announcement_order
		  redirect '/announce'
		end
    end
  end
  
  register HisaishiAnnouncements
end