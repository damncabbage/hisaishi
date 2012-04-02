require 'sinatra/base'
require 'rack/csrf'

module Sinatra
  module Csrf
    module Helpers
      # Insert an hidden tag with the anti-CSRF token into your forms.
      def csrf_tag
        Rack::Csrf.csrf_tag(env)
      end

      # Return the anti-CSRF token
      def csrf_token
        Rack::Csrf.csrf_token(env)
      end

      # Return the field name which will be looked for in the requests.
      def csrf_field
        Rack::Csrf.csrf_field
      end
    end

    # Turn on the anti-CSRF check. See Rack::Csrf documentation for the
    # available options.
    def apply_csrf_protection(options = {})
      opts = {:raise => true}.merge(options)
      use Rack::Csrf, opts
      helpers Csrf::Helpers
    end
  end

  register Csrf
end