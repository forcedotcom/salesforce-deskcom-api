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

module DeskApi::Configuration
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

    def included(base)
      if Gem::Version.new(Faraday::VERSION) >= Gem::Version.new('0.9.0')
        Faraday::Request.register_middleware desk_encode_json: DeskApi::Request::EncodeJson
        Faraday::Request.register_middleware desk_oauth: DeskApi::Request::OAuth
        Faraday::Request.register_middleware desk_retry: DeskApi::Request::Retry
        Faraday::Response.register_middleware desk_parse_dates: DeskApi::Response::ParseDates
        Faraday::Response.register_middleware desk_parse_json: DeskApi::Response::ParseJson
        Faraday::Response.register_middleware desk_raise_error: DeskApi::Response::RaiseError
      else
        Faraday.register_middleware :request, desk_encode_json: DeskApi::Request::EncodeJson
        Faraday.register_middleware :request, desk_oauth: DeskApi::Request::OAuth
        Faraday.register_middleware :request, desk_retry: DeskApi::Request::Retry
        Faraday.register_middleware :response, desk_parse_dates: DeskApi::Response::ParseDates
        Faraday.register_middleware :response, desk_parse_json: DeskApi::Response::ParseJson
        Faraday.register_middleware :response, desk_raise_error: DeskApi::Response::RaiseError
      end
    end
  end

  # if subdomain is set make sure endpoint is correct
  def endpoint
    @endpoint ||= "https://#{@subdomain}.desk.com"
  end

  def middleware
    @middleware ||= Proc.new do |builder|
      builder.request :desk_encode_json
      builder.request :basic_auth, @username, @password if basic_auth.values.all?
      builder.request :desk_oauth, oauth if oauth.values.all?
      builder.request :desk_retry

      builder.response :desk_parse_dates
      builder.response :desk_raise_error, DeskApi::Error::ClientError
      builder.response :desk_raise_error, DeskApi::Error::ServerError
      builder.response :desk_parse_json

      builder.adapter Faraday.default_adapter
    end
  end

  def configure
    yield self
    validate_credentials!
    validate_endpoint!
    self
  end

  def reset!
    DeskApi::Configuration.keys.each do |key|
      send("#{key}=", DeskApi::Default.options[key])
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
    Hash[DeskApi::Configuration.keys.map{|key| [key, instance_variable_get(:"@#{key}")]}]
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
      raise(DeskApi::Error::ConfigurationError, "Invalid credentials: Either username/password or OAuth credentials must be specified.")
    end

    if oauth.values.all?
      oauth.each do |credential, value|
        next if value.nil?

        unless value.is_a?(String) || value.is_a?(Symbol)
          raise(DeskApi::Error::ConfigurationError, "Invalid #{credential} specified: #{value} must be a string or symbol.")
        end
      end
    end

    if basic_auth.values.all?
      basic_auth.each do |credential, value|
        next if value.nil?

        unless value.is_a?(String) || value.is_a?(Symbol)
          raise(DeskApi::Error::ConfigurationError, "Invalid #{credential} specified: #{value} must be a string or symbol.")
        end
      end
    end
  end

  def validate_endpoint!
    unless endpoint =~ /^#{URI::regexp}$/
      raise(DeskApi::Error::ConfigurationError, "Invalid endpoint specified: `#{endpoint}` must be a valid url.")
    end
  end
end
