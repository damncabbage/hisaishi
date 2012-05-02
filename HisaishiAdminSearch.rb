require 'rubygems'
require 'sinatra/base'
require 'sinatra/jsonp'
require 'natural_time'
require 'socket'

module Sinatra
  module HisaishiAdminSearch
    
    module Helpers
      
    end
    
    def self.registered(app)
      app.helpers HisaishiAdminSearch::Helpers
      
		app.get '/search' do
		  haml :search, :locals => {
			:authed => has_admin_pin
		  }
		end
		
		app.post '/search' do
		  songs = Song.search(params[:q])
		  haml :search_result, :locals => {
		    :songs => songs
		  }
		end
    end
  end
  
  register HisaishiAdminSearch
end