require 'faraday'

require 'desk_api/configuration'
require 'desk_api/action/link'
require 'desk_api/action/resource'
require 'desk_api/error/client_error'
require 'desk_api/error/parse_error'

require 'desk_api/resource'

module DeskApi
  class Client
    include DeskApi::Configuration
    include DeskApi::Action::Link
    include DeskApi::Action::Resource

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [DeskApi::Client]
    def initialize(options = {})
      DeskApi::Configuration.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] || DeskApi.instance_variable_get(:"@#{key}"))
      end

      # load the initial resources (should actually be a call to /api/v2 but not yet)
      resources = File.open(File.expand_path('resources.json', File.dirname(__FILE__))).read
      definition = Hashie::Mash.new(JSON.parse(resources))
      # on the client we only have links
      setup_links(definition._links)
    end

    # Perform an HTTP DELETE request
    def delete(path, params = {})
      request(:delete, path, params)
    end

    # Perform an HTTP GET request
    def get(path, params = {})
      request(:get, path, params)
    end

    # Perform an HTTP POST request
    def post(path, params = {})
      request(:post, path, params)
    end

    # Perform an HTTP PATCH request
    def patch(path, params = {})
      request(:patch, path, params)
    end
  
  private
    
    def request(method, path, params = {})
      connection.send(method, path, params)
    rescue Faraday::Error::ClientError
      raise DeskApi::Error::ClientError
    rescue JSON::ParserError
      raise DeskApi::Error::ParserError
    end

    def connection
      @connection ||= Faraday.new endpoint, connection_options, &middleware
    end
  end
end