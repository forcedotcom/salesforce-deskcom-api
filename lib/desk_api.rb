require 'uri'
require 'faraday'
require 'forwardable'
require 'addressable/uri'

# {DeskApi} allows for easy interaction with Desk.com's API.
# It is the top level namespace and delegates all missing
# methods to an automatically created client. This allows
# you to use {DeskApi} as a client which is not recommended
# if you have to connect to multiple Desk.com sites.
#
# @author    Thomas Stachl <tstachl@salesforce.com>
# @copyright Copyright (c) 2013-2014 Thomas Stachl
# @license   MIT
#
# @example configure the {DeskApi} client
#   DeskApi.configure |config|
#     config.username = 'user@example.com'
#     config.password = 'mysecretpassword'
#     config.endpoint = 'https://example.desk.com'
#   end
#
# @example use {DeskApi} to send requests
#   my_cases = DeskApi.cases # GET '/api/v2/cases'
module DeskApi
  require 'desk_api/version'
  require 'desk_api/configuration'
  require 'desk_api/client'

  class << self
    include DeskApi::Configuration

    # Returns the default {DeskApi::Client}
    #
    # @param options [Hash] optional configuration options
    # @return [DeskApi::Client]
    def client
      return @client if defined?(:@client) && @client.hash == options.hash
      @client = DeskApi::Client.new(options)
    end

    # Delegates missing methods to the default {DeskApi::Client}
    #
    # @return [DeskApi::Resource]
    def method_missing(method, *args, &block)
      client.send(method, *args, &block)
    end
  end

  # immediately reset the default client
  reset!
end
