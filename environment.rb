require 'rubygems'
require 'sinatra' unless defined?(Sinatra)
require 'active_resource'
require 'haml'
require 'sqlite3'
require 'data_mapper'
require 'dm-ar-finders'
require 'open-uri'
require 'cgi'
require "rack/csrf"

configure do
  enable :sessions
  set :basecamp_domain, ENV['BASECAMP_DOMAIN']
  set :files,        ENV['HISAISHI_FILES'] || "http://localhost:4567/music/"
  set :database_url, ENV['DATABASE_URL']   || "sqlite3://#{File.expand_path('data/hisaishi.sqlite', File.dirname(__FILE__))}"
  use Rack::Session::Cookie, :secret => ENV['RACK_COOKIE'] || "aaaaaaaaaaaaaaaboop"
  use Rack::Csrf, :raise => true
end

# Per-environment configs; use 'rake hisaishi:install' to create this with defaults.
environments_config = File.expand_path('config/environments.rb', File.dirname(__FILE__))
require environments_config if File.exists?(environments_config)

# Load models.
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/models")
Dir.glob("#{File.dirname(__FILE__)}/models/*.rb") { |models| require File.basename(models, '.*') }

DataMapper.finalize

# Load plugins (and step around /vendor/bundler).
load("#{File.dirname(__FILE__)}/vendor/sinatra_rack.rb")
Dir["#{File.dirname(__FILE__)}/vendor/{gems,plugins}/**/*.rb"].each { |f| load(f) }
DataMapper.setup(:default, settings.database_url)

