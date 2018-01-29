# Copyright (c) 2013-2018, Salesforce.com, Inc.
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
    # The {DeskApi::Response::RaiseError} middleware
    # raises errors that happen during the API request
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2018 Salesforce.com
    # @license   BSD 3-Clause License
    class RaiseError < Faraday::Response::Middleware
      # Checks the status code and raises the error if there
      # is a error class found for the status code
      #
      # @raise [DeskApi::Error]
      def on_complete(env)
        status_code = env[:status].to_i
        error_class = @klass.errors[status_code]
        raise error_class.from_response(env) if error_class
      end

      # Initializes this middleware with the specific class.
      def initialize(app, klass)
        @klass = klass
        super(app)
      end
    end
  end
end
