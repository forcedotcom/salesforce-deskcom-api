# Copyright (c) 2013-2014, Salesforce.com, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#   * Neither the name of Salesforce.com nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'desk_api/rate_limit'

module DeskApi
  # {DeskApi::Error} is the base error for all {DeskApi} errors.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2014 Salesforce.com
  # @license   BSD 3-Clause License
  class Error < StandardError
    attr_reader :rate_limit

    # Initializes a new Error object
    #
    # @param err [Exception, String]
    # @param headers [Hash]
    # @param code [Integer]
    # @param err_hash [Hash]
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
