require 'uri'
require 'json'
require 'forwardable'
require 'addressable/uri'

require 'hashie/mash'
require 'active_support/inflector'

require 'desk/configuration'
require 'desk/client'
require 'desk/version'

module Desk
  class << self
    include Desk::Configuration

    # Delegate to a Desk::Client
    #
    # @return [Desk::Client]
    def client
      return @client if instance_variable_defined?(:@client) && @client.hash == options.hash
      @client = Desk::Client.new(options)
    end

    def method_missing(method_name, *args, &block)
      return super unless respond_to_missing?(method_name)
      client.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name, include_private)
    end
  end
  setup
end