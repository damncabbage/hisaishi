#
# Change these depending on your settings.
# (This example setup assumes a SQLite dev and a Heroku production.)
#

configure do
  # eg. 'flyinghigh' for 'flyinghigh.basecamphq.com'
  #set :basecamp_domain, 'basecampaccountnamehere'
end

# Default to the below settings; replace if necessary:

configure :development do
  #set :files, 'http://localhost:4567/music/'
  #set :database_url, "sqlite3://#{File.expand_path('../data/hisaishi.sqlite', File.dirname(__FILE__))}"
end

configure :production do
  #set :files, 'http://yourexamplesite.com/music/'
  #set :database_url, ENV['DATABASE_URL'] # eg. for Heroku
end
