require 'desk_api/rate_limit'

module DeskApi
  # Custom error class for rescuing from all desk.com errors
  class Error < StandardError
    attr_reader :rate_limit

    # Initializes a new Error object
    #
    # @param exception [Exception, String]
    # @param response_headers [Hash]
    # @param code [Integer]
    # @return [DeskApi::Error]
    def initialize(exception=$!, response_headers={}, code = nil)
      @rate_limit = DeskApi::RateLimit.new(response_headers)
      @wrapped_exception = exception
      @code = code
      exception.respond_to?(:backtrace) ? super(exception.message) : super(exception.to_s)
    end

    def backtrace
      @wrapped_exception.respond_to?(:backtrace) ? @wrapped_exception.backtrace : super
    end

    class << self
      # Create a new error from an HTTP response
      #
      # @param response [Hash]
      # @return [DeskApi::Error]
      def from_response(response = {})
        error, code = parse_error(response[:body]), response[:status]
        new(error, response[:response_headers], code)
      end

      # @return [Hash]
      def errors
        @errors ||= descendants.each_with_object({}) do |klass, hash|
          hash[klass::HTTP_STATUS_CODE] = klass
        end
      end

      # @return [Array]
      def descendants
        @descendants ||= []
      end

      # @return [Array]
      def inherited(descendant)
        descendants << descendant
      end

    private

      def parse_error(body)
        if body['message']
          body['message']
        end
      end
    end
  end
end