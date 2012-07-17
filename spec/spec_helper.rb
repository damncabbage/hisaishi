require 'rubygems'
require 'sinatra'

set :environment, :test
require File.expand_path('../hisaishi.rb', File.dirname(__FILE__))

require 'rspec'
require 'capybara/rspec'
require 'factory_girl'
require 'ffaker'
require 'rack/test'

module ApiHelper
  def app
    @app ||= Sinatra::Application.new
  end
end

RSpec.configure do |config|
  config.before(:each) { DataMapper.auto_migrate! }
  config.include Rack::Test::Methods

  config.include ApiHelper, :type => :api
  config.include Capybara, :type => :request
  Capybara.app = Sinatra::Application.new
end

Dir[File.dirname(__FILE__) + '/factories/*.rb'].each { |f| require f }
