require 'faraday'
require 'desk/error/bad_gateway'
require 'desk/error/bad_request'
require 'desk/error/conflict'
require 'desk/error/forbidden'
require 'desk/error/gateway_timeout'
require 'desk/error/internal_server_error'
require 'desk/error/method_not_allowed'
require 'desk/error/not_acceptable'
require 'desk/error/not_found'
require 'desk/error/service_unavailable'
require 'desk/error/too_many_requests'
require 'desk/error/unauthorized'
require 'desk/error/unprocessable_entity'
require 'desk/error/unsupported_media_type'

module Desk
  module Response
    class RaiseError < Faraday::Response::Middleware
      def on_complete(env)
        status_code = env[:status].to_i
        error_class = @klass.errors[status_code]
        raise error_class.from_response(env) if error_class
      end

      def initialize(app, klass)
        @klass = klass
        super(app)
      end
    end

    Faraday.register_middleware :response, raise_error: lambda { RaiseError}
  end
end