require 'faraday'
require 'desk_api/error/bad_gateway'
require 'desk_api/error/bad_request'
require 'desk_api/error/conflict'
require 'desk_api/error/forbidden'
require 'desk_api/error/gateway_timeout'
require 'desk_api/error/internal_server_error'
require 'desk_api/error/method_not_allowed'
require 'desk_api/error/not_acceptable'
require 'desk_api/error/not_found'
require 'desk_api/error/service_unavailable'
require 'desk_api/error/too_many_requests'
require 'desk_api/error/unauthorized'
require 'desk_api/error/unprocessable_entity'
require 'desk_api/error/unsupported_media_type'

module DeskApi
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

    Faraday.register_middleware :response, :raise_desk_error => lambda { RaiseError}
  end
end