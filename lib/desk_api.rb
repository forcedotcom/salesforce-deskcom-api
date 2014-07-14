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

require 'uri'
require 'faraday'
require 'forwardable'

# {DeskApi} allows for easy interaction with Desk.com's API.
# It is the top level namespace and delegates all missing
# methods to an automatically created client. This allows
# you to use {DeskApi} as a client which is not recommended
# if you have to connect to multiple Desk.com sites.
#
# @author    Thomas Stachl <tstachl@salesforce.com>
# @copyright Copyright (c) 2013-2014 Salesforce.com
# @license   BSD 3-Clause License
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
