class Hisaishi < Padrino::Application
  register SassInitializer
  use ActiveRecord::ConnectionAdapters::ConnectionManagement
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers

  ### Padrino configuration ###

  enable :sessions
  set :logging, true # Logging in STDOUT for development and file for production (default only for development)
  # set :default_builder, "foo"   # Set a custom form builder (default 'StandardFormBuilder')

  ### Application configuration ###
  set :files, ENV['HISAISHI_FILES'] || "http://#{HostHelpers.my_first_non_loopback_ipv4}:#{settings.port}/music/"
  set :admin_pin, ENV['HISAISHI_PIN'] || '1234'

  ### Environment-specific configuration ###

  configure :development do
  end
  configure :test do
  end
  configure :production do
  end

  ### Component configuration options ###

  # Turn on JSONP for Rabl
  Rabl.configure do |config|
    config.enable_json_callbacks = true
  end

  # Stop haml being a dick.
  Haml::Template.options[:attr_wrapper] = '"'

  ### Error Pages ###

  # error 404 do
  #   render 'errors/404'
  # end
  # error 505 do
  #   render 'errors/505'
  # end

end
