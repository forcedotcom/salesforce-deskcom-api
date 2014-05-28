require 'desk_api/rate_limit'

module DeskApi
  # {DeskApi::Error} is the base error for all {DeskApi} errors.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2014 Thomas Stachl
  # @license   MIT
  class Error < StandardError
    attr_reader :rate_limit

    # Initializes a new Error object
    #
    # @param exception [Exception, String]
    # @param response_headers [Hash]
    # @param code [Integer]
    # @return [DeskApi::Error]
    def initialize(err = $ERROR_INFO, headers = {}, code = nil, err_hash = nil)
      @rate_limit = DeskApi::RateLimit.new(headers)
      @wrapped_err, @code, @errors = err, code, err_hash
      err.respond_to?(:backtrace) ? super(err.message) : super(err.to_s)
    end

    # Returns the backtrace of the wrapped exception if exits.
    #
    # @return [String]
    def backtrace
      @wrapped_err.respond_to?(:backtrace) ? @wrapped_err.backtrace : super
    end

    class << self
      # Create a new error from an HTTP response
      #
      # @param response [Hash]
      # @return [DeskApi::Error]
      def from_response(response = {})
        err_hash, error, code = parse_body(response[:body]) << response[:status]
        new(error, response[:response_headers], code, err_hash)
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

      # @return [Array]
      def parse_body(body = {})
        [body['errors'] || nil, body['message'] || nil]
      end
    end
  end
end
