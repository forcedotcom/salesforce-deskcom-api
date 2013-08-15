require 'spec_helper'

describe Desk::Configuration do
  context '#keys' do
    it 'returns an array of configuration keys' do
      Desk::Configuration.keys.should eq([
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
      Desk.reset!
    end

    it 'returns the endpoint if set' do
      Desk.endpoint = 'https://devel.desk.com'
      Desk.endpoint.should eq('https://devel.desk.com')
    end

    it 'returns the subdomain endpoint if subdomain is set' do
      Desk.subdomain = 'devel'
      Desk.endpoint.should eq('https://devel.desk.com')
    end

    it 'gives presidence to the endpoint' do
      Desk.subdomain = 'subdomain'
      Desk.endpoint = 'https://endpoint.desk.com'
      Desk.endpoint.should eq('https://endpoint.desk.com')
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
      client = Desk::Client.new
      client.configure do |config|
        @configuration.each do |key, value|
          config.send("#{key}=", value)
        end
      end

      Desk::Configuration.keys.each do |key|
        client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
      end
    end

    it 'throws an exception if credentials are not set' do
      client = Desk::Client.new
      lambda {
        client.configure do |config|
          @configuration.each do |key, value|
            config.send("#{key}=", value)
          end
          config.username = nil
          config.consumer_key = nil
        end
      }.should raise_error(Desk::Error::ConfigurationError)
    end

    it 'throws an exception if basic auth credentials are invalid' do
      client = Desk::Client.new
      lambda {
        client.configure do |config|
          @configuration.each do |key, value|
            config.send("#{key}=", value)
          end
          config.username = 1
          config.consumer_key = nil
        end
      }.should raise_error(Desk::Error::ConfigurationError)
    end

    it 'throws an exception if oauth credentials are invalid' do
      client = Desk::Client.new
      lambda {
        client.configure do |config|
          @configuration.each do |key, value|
            config.send("#{key}=", value)
          end
          config.username = nil
          config.consumer_key = 1
        end
      }.should raise_error(Desk::Error::ConfigurationError)
    end

    it 'throws an exception if endpoint is not a valid url' do
      client = Desk::Client.new
      lambda {
        client.configure do |config|
          @configuration.each do |key, value|
            config.send("#{key}=", value)
          end
          config.endpoint = 'some_funky_endpoint'
        end
      }.should raise_error(Desk::Error::ConfigurationError)
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
      client = Desk::Client.new
      client.configure do |config|
        @configuration.each do |key, value|
          config.send("#{key}=", value)
        end
      end
      client.reset!

      Desk::Configuration.keys.each do |key|
        client.instance_variable_get(:"@#{key}").should_not eq(@configuration[key])
      end
    end
  end

  context '#credentials?' do
    before do
      @client = Desk::Client.new
    end

    after do
      @client.reset!
    end

    it 'returns false if no authentication credentials are set' do
      @client.credentials?.should be_false
    end

    it 'returns true if basic auth credentials are set' do
      @client.username = 'UN'
      @client.password = 'PW'
      @client.credentials?.should be_true
    end

    it 'returns true if oauth credentials are set' do
      @client.consumer_key = 'CK'
      @client.consumer_secret = 'CS'
      @client.token = 'TOK'
      @client.token_secret = 'TOKS'
      @client.credentials?.should be_true
    end
  end
end