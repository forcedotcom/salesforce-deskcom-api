module DeskApi
  module Request
    # {DeskApi::Request::Retry} is a Faraday middleware that
    # retries failed requests up to 3 times. It also includes
    # desk.com's rate limiting which are retried only once.
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2014 Thomas Stachl
    # @license   MIT
    class Retry < Faraday::Middleware
      class << self
        # Returns an array of errors that should be retried.
        #
        # @return [Array]
        def errors
          @exceptions ||= [
            Errno::ETIMEDOUT,
            'Timeout::Error',
            Faraday::Error::TimeoutError,
            DeskApi::Error::TooManyRequests
          ]
        end
      end

      # Initializies the middleware and sets options
      #
      # @param app [Hash] the faraday environment hash
      # @param options [Hash] additional options
      def initialize(app, options = {})
        @max = options[:max] || 3
        @interval = options[:interval] || 10
        super(app)
      end

      # Rescues exceptions and retries the request
      #
      # @param env [Hash] the request hash
      def call(env)
        retries      = @max
        request_body = env[:body]
        begin
          env[:body] = request_body
          @app.call(env)
        rescue exception_matcher => err
          raise unless calc(err, retries) { |x| retries = x } > 0
          sleep interval(err)
          retry
        end
      end

      # Calculates the retries based on the error
      #
      # @param err [StandardError] the error that has been thrown
      # @param retries [Integer] current retry count
      # @return [Integer]
      def calc(err, retries, &block)
        # retry only once
        if err.kind_of?(DeskApi::Error::TooManyRequests) && retries == @max - 1
          block.call(0)
        else
          block.call(retries - 1)
        end
      end

      # Returns the interval for the specific error
      #
      # @param err [StandardError] the error that has been thrown
      # @return [Integer]
      def interval(err)
        if err.kind_of?(DeskApi::Error::TooManyRequests)
          err.rate_limit.reset_in
        else
          @interval
        end
      end

      # Returns an exception matcher
      #
      # @return [Module]
      def exception_matcher
        matcher = Module.new
        (class << matcher; self; end).class_eval do
          define_method(:===) do |error|
            Retry.errors.any? do |ex|
              ex.is_a?(Module) ? error.is_a?(ex) : error.class.to_s == ex.to_s
            end
          end
        end
        matcher
      end
    end
  end
end
