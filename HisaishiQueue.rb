require 'rubygems'
require 'sinatra/base'
require 'sinatra/jsonp'
require 'natural_time'
require 'socket'

module Sinatra
  module HisaishiQueue
    
    module Helpers
      def queue_songs
      	song_list = {}
      	HisaishiQueue.all.each do |q|
      		s = Song.get(q.song_id)
      		song_list[s.id] = s
      	end
	
      	{
	      	:songs => song_list,
      		:queue => HisaishiQueue.all(:order => [:queue_order.asc])
      	}
      end

      def reorder_queue(queue_ids)
      	i = 0
      	queue_ids.each do |q_id|
      		q = HisaishiQueue.get(q_id);
      		q.update(:queue_order => i)
      		i += 1
      	end
      end
    end
    
    def self.registered(app)
      	app.helpers HisaishiQueue::Helpers
      
		app.get '/queue' do
		  pin_auth
		  q = queue_songs
		  q[:authed] = has_admin_pin
		  haml :queue, :locals => q
		end

		app.get '/queue-info/:q_id' do
		  pin_auth!
		  q = HisaishiQueue.get(params[:q_id])
		  song = Song.get(q.song_id)
		  haml :queue_info, :locals => {
		  	:song => song,
		  	:q => q
		  }
		end

		app.post '/queue-info-process' do
		  pin_auth!
		  q = HisaishiQueue.get(params[:q_id])
		  puts params[:action]
  		
		  case params[:action]
		  when "now"
		  	q.play_now
		  when "next"
		  	q.play_next
		  when "last"
		  	q.play_last
		  when "stop"
		  	q.stop
		  when "prep"
		  	q.prep
		  when "play_next"
		  	q.play_next_now
		  when "pause"
		  	q.pause
		  when "unpause"
		  	q.unpause
		  end
		  
		  redirect '/queue'
		end

		app.get '/queue.jsonp' do
		  pin_auth!
		  out = queue_songs
		  JSONP out
		end

		app.get '/queue-delete/:q_id' do
		  pin_auth!
		  q = HisaishiQueue.get(params[:q_id])
		  song = Song.get(q.song_id)
		  haml :queue_delete_confirm, :locals => {
		  	:song => song,
		  	:q => q
		  }
		end

		app.post '/queue-delete-process' do
		  pin_auth!
		  q = HisaishiQueue.get(params[:q_id])
		  q.destroy
		  redirect '/queue'
		end

		app.post '/queue-reorder' do
		  pin_auth!
		  unless params[:queue].nil?
		    reorder_queue(params[:queue])
		  end
		end
    end
  end
  
  register HisaishiQueue
end