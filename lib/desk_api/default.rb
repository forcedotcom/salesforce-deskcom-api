# Copyright (c) 2013-2016, Salesforce.com, Inc.
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
  # {DeskApi::Default} contains the default configuration for each
  # {DeskApi::Client}.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2016 Salesforce.com
  # @license   BSD 3-Clause License
  module Default
    CONNECTION_OPTIONS = {
      headers: {
        accept: 'application/json',
        user_agent: "desk.com Ruby Gem v#{DeskApi::VERSION}"
      },
      request: {
        open_timeout: 5,
        timeout: 10
      }
    } unless defined? DeskApi::Default::CONNECTION_OPTIONS

    class << self
      # A hash of all the options
      #
      # @return [Hash]
      def options
        Hash[DeskApi::Configuration.keys.map { |key| [key, send(key)] }]
      end

      # The username if environmental variable is set
      #
      # @return [String]
      def username
        ENV['DESK_USERNAME']
      end

      # The password if environmental variable is set
      #
      # @return [String]
      def password
        ENV['DESK_PASSWORD']
      end

      # The consumer key if environmental variable is set
      #
      # @return [String]
      def consumer_key
        ENV['DESK_CONSUMER_KEY']
      end

      # The consumer secret if environmental variable is set
      #
      # @return [String]
      def consumer_secret
        ENV['DESK_CONSUMER_SECRET']
      end

      # The access token if environmental variable is set
      #
      # @return [String]
      def token
        ENV['DESK_TOKEN']
      end

      # The access token secret if environmental variable is set
      #
      # @return [String]
      def token_secret
        ENV['DESK_TOKEN_SECRET']
      end

      # The subdomain if environmental variable is set
      #
      # @return [String]
      def subdomain
        ENV['DESK_SUBDOMAIN']
      end

      # The endpoint if environmental variable is set
      #
      # @return [String]
      def endpoint
        ENV['DESK_ENDPOINT']
      end

      # The connection options hash
      #
      # @return [Hash]
      def connection_options
        CONNECTION_OPTIONS
      end
    end
  end
end
