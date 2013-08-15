require 'faraday'
require 'faraday_middleware'

require 'typhoeus'
require 'typhoeus/adapters/faraday'

require 'desk/default'
require 'desk/request/retry'
require 'desk/response/raise_error'
require 'desk/error/configuration_error'
require 'desk/error/client_error'
require 'desk/error/server_error'

module Desk
  module Configuration
    extend Forwardable
    attr_writer :consumer_secret, :token, :token_secret, :password
    attr_accessor :consumer_key, :username, :endpoint, :subdomain, :connection_options, :middleware
    def_delegator :options, :hash

    class << self
      def keys
        @keys ||= [
          :consumer_key,
          :consumer_secret,
          :token,
          :token_secret,
          :username,
          :password,
          :subdomain,
          :endpoint,
          :connection_options
        ]
      end
    end

    # if subdomain is set make sure endpoint is correct
    def endpoint
      @endpoint ||= "https://#{@subdomain}.desk.com"
    end

    def middleware
      @middleware ||= Proc.new do |builder|
        builder.request :basic_auth, @username, @password if basic_auth.values.all?
        builder.request :oauth, oauth if oauth.values.all?
        builder.request :json
        builder.request :retry

        builder.response :mashify
        builder.response :dates
        builder.response :raise_error, Desk::Error::ClientError
        builder.response :raise_error, Desk::Error::ServerError
        builder.response :json, content_type: /application\/json/

        builder.adapter :typhoeus
      end
    end

    def configure
      yield self
      validate_credentials!
      validate_endpoint!
      self
    end

    def reset!
      Desk::Configuration.keys.each do |key|
        send("#{key}=", Desk::Default.options[key])
      end
      self
    end
    alias setup reset!

    def credentials?
      oauth.values.all? || basic_auth.values.all?
    end

  private
    # @return [Hash]
    def options
      Hash[Desk::Configuration.keys.map{|key| [key, instance_variable_get(:"@#{key}")]}]
    end

    def oauth
      {
        consumer_key: @consumer_key,
        consumer_secret: @consumer_secret,
        token: @token,
        token_secret: @token_secret
      }
    end

    def basic_auth
      {
        username: @username,
        password: @password
      }
    end

    def validate_credentials!
      unless credentials?
        raise(Error::ConfigurationError, "Invalid credentials: Either username/password or OAuth credentials must be specified.")
      end

      if oauth.values.all?
        oauth.each do |credential, value|
          next if value.nil?

          unless value.is_a?(String) || value.is_a?(Symbol)
            raise(Error::ConfigurationError, "Invalid #{credential} specified: #{value} must be a string or symbol.")
          end
        end
      end

      if basic_auth.values.all?
        basic_auth.each do |credential, value|
          next if value.nil?

          unless value.is_a?(String) || value.is_a?(Symbol)
            raise(Error::ConfigurationError, "Invalid #{credential} specified: #{value} must be a string or symbol.")
          end
        end
      end
    end

    def validate_endpoint!
      unless endpoint =~ /^#{URI::regexp}$/
        raise(Error::ConfigurationError, "Invalid endpoint specified: `#{endpoint}` must be a valid url.")
      end
    end
  end
end