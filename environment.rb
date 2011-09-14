require 'rubygems'
require 'sinatra' unless defined?(Sinatra)
require 'active_resource'
require 'haml'
require 'sqlite3'
require 'data_mapper'
require 'dm-ar-finders'
require 'open-uri'
require 'cgi'

configure do
  enable :sessions
  set :basecamp_domain, ENV['BASECAMP_DOMAIN']
  set :files,        ENV['HISAISHI_FILES'] || "http://localhost:4567/music/"
  set :database_url, ENV['DATABASE_URL']   || "sqlite3://#{File.expand_path('data/hisaishi.sqlite', File.dirname(__FILE__))}"
end

# Per-environment configs; use 'rake hisaishi:install' to create this with defaults.
environments_config = File.expand_path('config/environments.rb', File.dirname(__FILE__))
require environments_config if File.exists?(environments_config)

# Load models.
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/models")
Dir.glob("#{File.dirname(__FILE__)}/models/*.rb") { |models| require File.basename(models, '.*') }

# Load plugins (and step around /vendor/bundler).
Dir["#{File.dirname(__FILE__)}/vendor/{gems,plugins}/**/*.rb"].each { |f| load(f) }
DataMapper.setup(:default, settings.database_url)

