require 'uri'
require 'faraday'
require 'forwardable'
require 'addressable/uri'

module DeskApi
  require 'desk_api/version'
  require 'desk_api/configuration'
  require 'desk_api/client'

  class << self
    include DeskApi::Configuration

    # Delegate to a DeskApi::Client
    #
    # @return [DeskApi::Client]
    def client
      return @client if instance_variable_defined?(:@client) && @client.hash == options.hash
      @client = DeskApi::Client.new(options)
    end

    def method_missing(method_name, *args, &block)
      client.send(method_name, *args, &block)
    end
  end

  setup
end
