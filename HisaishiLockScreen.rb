require 'rubygems'
require 'sinatra/base'
require 'sinatra/jsonp'
require 'natural_time'
require 'socket'

module Sinatra
  module HisaishiLockScreen
    
    module Helpers
      
    end
    
    def self.registered(app)
      	app.helpers HisaishiLockScreen::Helpers
      
		app.get '/lock-screen' do
		  session.clear
		  return_path = params[:return_path].nil? ? 'queue' : params[:return_path]
		  haml :pin_entry, :locals => {
		    :return_path => return_path
		  }
		end
		
		app.post '/unlock-screen' do
		  session[:admin_pin] = params[:pin]
		  state = {
		    :authed => has_admin_pin
		  }
		  JSONP state
		end
    end
  end
  
  register HisaishiLockScreen
end