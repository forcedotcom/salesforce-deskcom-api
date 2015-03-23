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

module DeskApi
  module Request
    # {DeskApi::Request::EncodeJson} is the Faraday middleware
    # that dumps a json string from whatever is specified in
    # the request body. It also sets the "Content-Type" header.
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2014 Salesforce.com
    # @license   BSD 3-Clause License
    class EncodeDates < Faraday::Middleware
      # Changes the request before it gets sent
      #
      # @param env [Hash] the request hash
      def call(env)
        if env[:body] && !env[:body].to_s.empty?
          env[:body] = encode_dates(env[:body])
        end
        @app.call env
      end

      private

      # Encodes all {Date}, {DateTime} and {Time} values
      # to iso8601
      #
      # @param value [Mixed] the current body
      def encode_dates(value)
        case value
        when Hash
          value.each_pair do |key, element|
            value[key] = encode_dates element
          end
        when Array
          value.each_with_index do |element, index|
            value[index] = encode_dates element
          end
        when DateTime, Date, Time
          value.to_time.utc.iso8601
        else
          value
        end
      end
    end
  end
end
