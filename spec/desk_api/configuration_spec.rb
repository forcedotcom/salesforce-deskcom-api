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

require 'spec_helper'

describe DeskApi::Configuration do
  context '#keys' do
    it 'returns an array of configuration keys' do
      expect(DeskApi::Configuration.keys).to eq([
        :consumer_key,
        :consumer_secret,
        :token,
        :token_secret,
        :username,
        :password,
        :subdomain,
        :endpoint,
        :connection_options
      ])
    end
  end

  context '#endpoint' do
    after(:each) do
      DeskApi.reset!
    end

    it 'returns the endpoint if set' do
      DeskApi.endpoint = 'https://devel.desk.com'
      expect(DeskApi.endpoint).to eq('https://devel.desk.com')
    end

    it 'returns the subdomain endpoint if subdomain is set' do
      DeskApi.subdomain = 'devel'
      expect(DeskApi.endpoint).to eq('https://devel.desk.com')
    end

    it 'gives presidence to the endpoint' do
      DeskApi.subdomain = 'subdomain'
      DeskApi.endpoint = 'https://endpoint.desk.com'
      expect(DeskApi.endpoint).to eq('https://endpoint.desk.com')
    end
  end

  context '#configure' do
    before do
      @configuration = {
        consumer_key: 'CK',
        consumer_secret: 'CS',
        token: 'TOK',
        token_secret: 'TOKS',
        username: 'UN',
        password: 'PW',
        subdomain: 'devel',
        endpoint: 'https://devel.desk.com',
        connection_options: {
          request: { timeout: 10 }
        }
      }
    end

    it 'overrides the module configuration' do
      client = DeskApi::Client.new
      client.configure do |config|
        @configuration.each do |key, value|
          config.send("#{key}=", value)
        end
      end

      DeskApi::Configuration.keys.each do |key|
        expect(client.instance_variable_get(:"@#{key}")).to eq(@configuration[key])
      end
    end

    it 'throws an exception if credentials are not set' do
      client = DeskApi::Client.new
      expect(
        lambda {
          client.configure do |config|
            @configuration.each do |key, value|
              config.send("#{key}=", value)
            end
            config.username = nil
            config.consumer_key = nil
          end
        }
      ).to raise_error(DeskApi::Error::ConfigurationError)
    end

    it 'throws an exception if basic auth credentials are invalid' do
      client = DeskApi::Client.new
      expect(
        lambda {
          client.configure do |config|
            @configuration.each do |key, value|
              config.send("#{key}=", value)
            end
            config.username = 1
            config.consumer_key = nil
          end
        }
      ).to raise_error(DeskApi::Error::ConfigurationError)
    end

    it 'throws an exception if oauth credentials are invalid' do
      client = DeskApi::Client.new
      expect(
        lambda {
          client.configure do |config|
            @configuration.each do |key, value|
              config.send("#{key}=", value)
            end
            config.username = nil
            config.consumer_key = 1
          end
        }
      ).to raise_error(DeskApi::Error::ConfigurationError)
    end

    it 'throws an exception if endpoint is not a valid url' do
      client = DeskApi::Client.new
      expect(
        lambda {
          client.configure do |config|
            @configuration.each do |key, value|
              config.send("#{key}=", value)
            end
            config.endpoint = 'some_funky_endpoint'
          end
        }
      ).to raise_error(DeskApi::Error::ConfigurationError)
    end
  end

  context '#reset!' do
    before do
      @configuration = {
        consumer_key: 'CK',
        consumer_secret: 'CS',
        token: 'TOK',
        token_secret: 'TOKS',
        username: 'UN',
        password: 'PW',
        subdomain: 'devel',
        endpoint: 'https://devel.desk.com',
        connection_options: {
          request: { timeout: 10 }
        }
      }
    end

    it 'resets the configuration to module defaults' do
      client = DeskApi::Client.new
      client.configure do |config|
        @configuration.each do |key, value|
          config.send("#{key}=", value)
        end
      end
      client.reset!

      DeskApi::Configuration.keys.each do |key|
        expect(client.instance_variable_get(:"@#{key}")).not_to eq(@configuration[key])
      end
    end
  end

  context '#credentials?' do
    before do
      @client = DeskApi::Client.new
    end

    after do
      @client.reset!
    end

    it 'returns false if no authentication credentials are set' do
      expect(@client.credentials?).to eq(false)
    end

    it 'returns true if basic auth credentials are set' do
      @client.username = 'UN'
      @client.password = 'PW'
      expect(@client.credentials?).to eq(true)
    end

    it 'returns true if oauth credentials are set' do
      @client.consumer_key = 'CK'
      @client.consumer_secret = 'CS'
      @client.token = 'TOK'
      @client.token_secret = 'TOKS'
      expect(@client.credentials?).to eq(true)
    end
  end
end
