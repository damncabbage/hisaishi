require 'rubygems'
require 'sinatra' unless defined?(Sinatra)
require 'haml'
require 'sqlite3'
require 'data_mapper'
require 'dm-ar-finders'

configure do
  enable :sessions
  set :host, 'smashconvention'
  set :files, 'http://localhost:4567/music/'
  
  # Load models.
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
  
  # Load plugins.
  Dir["#{File.dirname(__FILE__)}/vendor/{gems,plugins}/**/*.rb"].each { |f| load(f) }

  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/data/hisaishi.sqlite")
end