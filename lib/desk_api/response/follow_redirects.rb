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

require 'desk_api/error/follow_redirect_error'

module DeskApi
  module Response
    # The {DeskApi::Response::FollowRedirects} middleware
    # follows redirects automatically
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2018 Salesforce.com
    # @license   BSD 3-Clause License
    class FollowRedirects < Faraday::Response::Middleware
      dependency 'uri'

      # Status codes we need to redirect
      REDIRECT_HTTP_CODES  = Set.new [301, 302, 303, 307]
      # Redirection limit
      MAX_REDIRECT_LIMIT   = 3

      # Wrapps the call to have a limit countdown
      def call(env)
        perform env, MAX_REDIRECT_LIMIT
      end

      private

      # Performs the call and checks and performs a redirect
      # if the status is one in 301, 302, 303 or 307
      #
      # @param env [Hash]
      # @param limit [Integer]
      # @raise DeskApi::Error::FollowRedirectError
      # @return [Faraday::Response]
      def perform(env, limit)
        body     = env[:body]
        response = @app.call(env)

        response.on_complete do |env|
          if REDIRECT_HTTP_CODES.include? response.status
            raise ::DeskApi::Error::FollowRedirectError, response if limit.zero?
            env      = reset_env(env, body, response)
            response = perform(env, limit - 1)
          end
        end

        response
      end

      # Changes the environment based on the response, eg.
      # it sets the new url, resets the body, ...
      #
      # @param env [Hash]
      # @param body [String]
      # @param response [Faraday::Response]
      # @return [Hash]
      def reset_env(env, body, response)
        env.tap do |env|
          location   = ::URI.parse response['location']

          # ugly hack so attachments will work
          if location.host != env[:url].host
            env[:request_headers] = {}
          end

          env[:url]  = location
          env[:body] = body
          %w(status response response_headers).each{ |k| env.delete k }
        end
      end
    end
  end
end
