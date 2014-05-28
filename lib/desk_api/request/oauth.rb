module DeskApi
  module Request
    # {DeskApi::Request::OAuth} is the Faraday middleware to
    # sign requests with an OAuth header.
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2014 Thomas Stachl
    # @license   MIT
    class OAuth < Faraday::Middleware
      dependency 'simple_oauth'

      # Initializies the middleware and sets options
      #
      # @param app [Hash] the faraday environment hash
      # @param options [Hash] additional options
      def initialize(app, options)
        super(app)
        @options = options
      end

      # Changes the request before it gets sent
      #
      # @param env [Hash] the request hash
      def call(env)
        env[:request_headers]['Authorization'] = oauth(env).to_s
        @app.call env
      end

      private

      # Returns the OAuth header
      #
      # @param env [Hash] the request hash
      # @return [String]
      def oauth(env)
        SimpleOAuth::Header.new env[:method], env[:url].to_s, {}, @options
      end
    end
  end
end
