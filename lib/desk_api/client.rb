require 'desk_api/resource'
require 'desk_api/error/parser_error'

module DeskApi
  # The {DeskApi::Client} builds and performs the
  # http request using Faraday and the configured
  # adapter. It includes and has full access to
  # the configuration module.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2014 Thomas Stachl
  # @license   MIT
  class Client
    include DeskApi::Configuration

    # Initializes a new client object
    #
    # @param options [Hash] optional configuration hash
    # @return [DeskApi::Client] the new client
    def initialize(options = {})
      DeskApi::Configuration.keys.each do |key|
        value = options[key] || DeskApi.instance_variable_get(:"@#{key}")
        instance_variable_set(:"@#{key}", value)
      end
    end

    # Perform an http request
    #
    # @param path [String] the url path to the resource
    # @param params [Hash] optional additional url params
    # @yield [Faraday::Response] for further request customizations.
    # @return [Faraday::Response]
    %w(get head delete post patch).each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(path, params = {}, &block)
          request(:#{method}, path, params, &block)
        end
      RUBY
    end

    # Returns a new resource for the given path
    #
    # @param path [String] the url path to the resource
    # @return [DeskApi::Resource]
    def by_url(path)
      DeskApi::Resource.new(self, DeskApi::Resource.build_self_link(path))
    end

    private

    # Returns a new resource based on the method you're trying to load:
    #
    # @example request cases
    #   my_cases = client.cases # GET '/api/v2/cases'
    # @param method [Symbol] the method called
    # @param params [Hash] additional query params
    # @yield [DeskApi::Resource]
    # @return [DeskApi::Resource]
    def method_missing(method, params = {})
      definition = DeskApi::Resource.build_self_link("/api/v2/#{method}")
      DeskApi::Resource.new(self, definition).tap do |res|
        res.query_params = params
        yield res if block_given?
      end
    end

    # Hands off the request to Faraday for further processing
    #
    # @param method [Symbol] the http method to call
    # @param path [String] the url path to the resource
    # @param params [Hash] optional additional url params
    # @yield [Faraday::Response] for further request customizations.
    # @return [Faraday::Response]
    # @raises [DeskApi::Error::ClientError]
    # @raises [DeskApi::Error::ParserError]
    def request(method, path, params = {}, &block)
      connection.send(method, path, params, &block)
    rescue Faraday::Error::ClientError
      raise DeskApi::Error::ClientError
    rescue JSON::ParserError
      raise DeskApi::Error::ParserError
    end

    # Builds and/or returns the Faraday client.
    # @returns [Faraday::Connection]
    def connection
      @connection ||= Faraday.new endpoint, connection_options, &middleware
    end
  end
end
