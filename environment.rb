require 'rubygems'
require 'sinatra' unless defined?(Sinatra)
require 'active_resource'
require 'haml'
require 'sqlite3'
require 'data_mapper'
require 'dm-ar-finders'
require 'open-uri'
require 'cgi'

# Change these depending on your settings.

configure do
  set :basecamp_domain, 'smashconvention'
end

configure :development do
  set :files, 'http://localhost:4567/music/'
end

configure :production do
  set :files, 'http://allthethings.smash.org.au/karaoke/'
end

# No need to change anything below this point.

configure do
  enable :sessions
  
  # Load models.
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/models")
  Dir.glob("#{File.dirname(__FILE__)}/models/*.rb") { |models| require File.basename(models, '.*') }
  
  # Load plugins.
  Dir["#{File.dirname(__FILE__)}/vendor/{gems,plugins}/**/*.rb"].each { |f| load(f) }

  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/data/hisaishi.sqlite")
end