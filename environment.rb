require 'sinatra' unless defined?(Sinatra)
require 'active_resource'
require 'haml'
require 'data_mapper'
require 'dm-ar-finders'
require 'open-uri'
require 'cgi'
require 'json'
#require "rack/csrf"
require "active_support/all"

# Load plugins (and step around /vendor/bundler).
require "#{File.dirname(__FILE__)}/vendor/sinatra_rack.rb"
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/models/**/*.rb"].each { |f| require f }
#Dir["#{File.dirname(__FILE__)}/vendor/{gems,plugins}/**/*.rb"].each { |f| load(f) }

# Global config
configure do
  enable :sessions
  set :basecamp_domain, nil
  set :defaults_to_queue, ENV['DEFAULTS_TO_QUEUE'] == 1 || false
  set :views, File.dirname(__FILE__) + "/views"
end

# Per-environment config
require File.expand_path('config/environments.rb', File.dirname(__FILE__))

# Stop haml being a dick.
Haml::Template.options[:attr_wrapper] = '"'

# Model setup
DataMapper.finalize
DataMapper.setup(:default, settings.database_url)

