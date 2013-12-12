require 'desk_api/resource'
require 'desk_api/error/parser_error'

class DeskApi::Client
  include DeskApi::Configuration

  # Initializes a new Client object
  #
  # @param options [Hash]
  # @return [DeskApi::Client]
  def initialize(options = {})
    DeskApi::Configuration.keys.each do |key|
      instance_variable_set(:"@#{key}", options[key] || DeskApi.instance_variable_get(:"@#{key}"))
    end
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
  # If the method is missing create a resource
  def method_missing(method, *args, &block)
    DeskApi::Resource.new(self, DeskApi::Resource.build_self_link("/api/v2/#{method}"))
  end

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