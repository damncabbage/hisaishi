#
# Change these depending on your settings.
# (This example setup assumes a SQLite dev and a Heroku production.)
#

include Net::IpHelpers

# Local Dev
configure :development do
  require 'sqlite3'
  set :files, "http://#{local_private_or_loopback_ipv4}:4567/music/"
  set :database_url, "sqlite3://#{File.expand_path('../db/development.sqlite3', File.dirname(__FILE__))}"
  set :admin_pin, '1234'
  use Rack::Session::Cookie, :secret => "aaaaaaaaaaaaaaaboop"
end

# Local Testing
configure :test do
  require 'sqlite3'
  set :files, "http://#{local_private_or_loopback_ipv4}:4567/music/"
  set :database_url, "sqlite3://#{File.expand_path('../db/test.sqlite3', File.dirname(__FILE__))}"
  set :admin_pin, '1234'
  use Rack::Session::Cookie, :secret => "aaaaaaaaaaaaaaaboop"
end

# Karaoke Room
configure :room do
  require 'sqlite3'
  set :files, ENV['HISAISHI_FILES'] || "http://#{local_private_or_loopback_ipv4}:4567/music/"
  set :database_url, "sqlite3://#{File.expand_path('../db/room.sqlite3', File.dirname(__FILE__))}"
  set :admin_pin, ENV['ADMIN_PIN']
  use Rack::Session::Cookie, :secret => ENV['RACK_COOKIE']
end

# Heroku
configure :production do
  set :files, ENV['HISAISHI_FILES'] # eg. 'http://allthethings.smash.org.au/karaoke/'
  set :database_url, ENV['DATABASE_URL']
  set :admin_pin, ENV['ADMIN_PIN']
  use Rack::Session::Cookie, :secret => ENV['RACK_COOKIE']
end
