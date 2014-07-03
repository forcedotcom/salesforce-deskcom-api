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

require 'faraday'

require 'desk_api/default'
require 'desk_api/request/retry'
require 'desk_api/request/oauth'
require 'desk_api/request/encode_json'
require 'desk_api/response/parse_dates'
require 'desk_api/response/parse_json'
require 'desk_api/response/raise_error'
require 'desk_api/error/configuration_error'
require 'desk_api/error/client_error'
require 'desk_api/error/server_error'

module DeskApi
  # {DeskApi::Configuration} allows to configure a {DeskApi::Client}.
  # It exposes all available configuration options to the client and
  # makes sure secrets are only readable by the client.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2014 Salesforce.com
  # @license   BSD 3-Clause License
  module Configuration
    extend Forwardable
    attr_writer :consumer_secret, :token, :token_secret, :password
    attr_accessor :consumer_key, :username, :endpoint, :subdomain, \
                  :connection_options, :middleware
    def_delegator :options, :hash

    class << self
      # Returns an array of possible configuration options.
      #
      # @return [Array]
      def keys
        @keys ||= [
          :consumer_key, :consumer_secret, :token, :token_secret,
          :username, :password,
          :subdomain, :endpoint,
          :connection_options
        ]
      end

      # Allows to register middleware for Faraday v0.8 and v0.9
      #
      # @param type [Symbol] either :request or :response
      # @param sym [Symbol] the symbol to register the middleware as
      # @param cls [Symbol] the class name of the middleware
      def register_middleware(type, sym, cls)
        cls = DeskApi.const_get(type.capitalize).const_get(cls)
        if Faraday.respond_to?(:register_middleware)
          Faraday.register_middleware type, sym => cls
        else
          Faraday.const_get(type.capitalize).register_middleware sym => cls
        end
      end

      # Registers the middleware when the module is included.
      def included(_base)
        register_middleware :request, :desk_encode_json, :EncodeJson
        register_middleware :request, :desk_oauth, :OAuth
        register_middleware :request, :desk_retry, :Retry
        register_middleware :response, :desk_parse_dates, :ParseDates
        register_middleware :response, :desk_parse_json, :ParseJson
        register_middleware :response, :desk_raise_error, :RaiseError
      end
    end

    # Builds the endpoint using the subdomain if the endpoint isn't set
    #
    # @return [String]
    def endpoint
      @endpoint ||= "https://#{@subdomain}.desk.com"
    end

    # Returns the middleware proc to be used by Faraday
    #
    # @return [Proc]
    def middleware
      @middleware ||= proc do |builder|
        builder.request(:desk_encode_json)
        builder.request(*authorize_request)
        builder.request(:desk_retry)

        builder.response(:desk_parse_dates)
        builder.response(:desk_raise_error, DeskApi::Error::ClientError)
        builder.response(:desk_raise_error, DeskApi::Error::ServerError)
        builder.response(:desk_parse_json)

        builder.adapter(Faraday.default_adapter)
      end
    end

    # Allows to configure the client by yielding self.
    #
    # @yield [DeskApi::Client]
    # @return [DeskApi::Client]
    def configure
      yield self
      validate_credentials!
      validate_endpoint!
      self
    end

    # Resets the client to the default settings.
    #
    # @return [DeskApi::Client]
    def reset!
      DeskApi::Configuration.keys.each do |key|
        send("#{key}=", DeskApi::Default.options[key])
      end
      self
    end
    alias_method :setup, :reset!

    # Returns true if either all oauth values or all basic auth
    # values are set.
    #
    # @return [Boolean]
    def credentials?
      oauth.values.all? || basic_auth.values.all?
    end

    private

    # Returns a hash of current configuration options.
    #
    # @return [Hash]
    def options
      Hash[
        DeskApi::Configuration.keys.map do |key|
          [key, instance_variable_get(:"@#{key}")]
        end
      ]
    end

    # Returns the oauth configuration options.
    #
    # @return [Hash]
    def oauth
      {
        consumer_key: @consumer_key,
        consumer_secret: @consumer_secret,
        token: @token,
        token_secret: @token_secret
      }
    end

    # Returns the basic auth configuration options.
    #
    # @return [Hash]
    def basic_auth
      {
        username: @username,
        password: @password
      }
    end

    # Returns an array to authorize a request in the
    # middleware proc.
    #
    # @return [Array]
    def authorize_request
      if basic_auth.values.all?
        [:basic_auth, @username, @password]
      else
        [:desk_oauth, oauth]
      end
    end

    # Raises an error if credentials are not set or of
    # the wrong type.
    #
    # @raise [DeskApi::Error::ConfigurationError]
    def validate_credentials!
      fail(
        DeskApi::Error::ConfigurationError, 'Invalid credentials: ' \
        'Either username/password or OAuth credentials must be specified.'
      ) unless credentials?

      validate_oauth! if oauth.values.all?
      validate_basic_auth! if basic_auth.values.all?
    end

    # Raises an error if credentials are of the wrong type.
    #
    # @raise [DeskApi::Error::ConfigurationError]
    %w(oauth basic_auth).each do |type|
      define_method(:"validate_#{type}!") do
        send(type.to_sym).each_pair do |credential, value|
          next if value.nil?

          fail(
            DeskApi::Error::ConfigurationError, "Invalid #{credential} " \
            "specified: #{value} must be a string or symbol."
          ) unless value.is_a?(String) || value.is_a?(Symbol)
        end
      end
    end

    # Raises an error if the endpoint is not a valid URL.
    #
    # @raises [DeskApi::Error::ConfigurationError]
    def validate_endpoint!
      fail(
        DeskApi::Error::ConfigurationError,
        "Invalid endpoint specified: `#{endpoint}` must be a valid url."
      ) unless endpoint =~ /^#{URI.regexp}$/
    end
  end
end
