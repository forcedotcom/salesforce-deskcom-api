module DeskApi
  module Request
    # {DeskApi::Request::EncodeJson} is the Faraday middleware
    # that dumps a json string from whatever is specified in
    # the request body. It also sets the "Content-Type" header.
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2014 Thomas Stachl
    # @license   MIT
    class EncodeJson < Faraday::Middleware
      dependency 'json'

      # Changes the request before it gets sent
      #
      # @param env [Hash] the request hash
      def call(env)
        env[:request_headers]['Content-Type'] = 'application/json'
        if env[:body] && !env[:body].to_s.empty?
          env[:body] = ::JSON.dump(env[:body])
        end
        @app.call env
      end
    end
  end
end
