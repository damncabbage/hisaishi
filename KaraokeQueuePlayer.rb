require 'rubygems'
require 'sinatra/base'
require 'sinatra/jsonp'
require 'natural_time'
require 'socket'

module Sinatra
  module KaraokeQueuePlayer
    
    module Helpers
      
    end
    
    def self.registered(app)
      	app.helpers KaraokeQueuePlayer::Helpers
      
		app.get '/player' do
		  haml :player, :locals => {}
		end
    end
  end
  
  register KaraokeQueuePlayer
end
