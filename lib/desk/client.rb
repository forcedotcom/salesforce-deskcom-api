require 'faraday'

require 'desk/configuration'
require 'desk/action/link'
require 'desk/action/resource'
require 'desk/error/client_error'
require 'desk/error/parse_error'

require 'desk/resource'

module Desk
  class Client
    include Desk::Configuration
    include Desk::Action::Link
    include Desk::Action::Resource

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [Desk::Client]
    def initialize(options = {})
      Desk::Configuration.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] || Desk.instance_variable_get(:"@#{key}"))
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
      raise Desk::Error::ClientError
    rescue JSON::ParserError
      raise Desk::Error::ParserError
    end

    def connection
      @connection ||= Faraday.new endpoint, connection_options, &middleware
    end
  end
end