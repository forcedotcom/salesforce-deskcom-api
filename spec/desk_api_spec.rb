require 'spec_helper'

describe DeskApi do
  describe '.method_missing' do
    it 'delegates to DeskApi::Client' do
      DeskApi.method_missing(:endpoint).should be_a(String)
    end
  end

  describe '.respond_to_missing?' do
    it 'delegates to DeskApi::Client' do
      DeskApi.respond_to_missing?(:endpoint).should be_true
    end

    it 'takes an optional argument' do
      DeskApi.respond_to_missing?(:endpoint, true).should be_true
    end
  end

  describe '.client' do
    it 'should return a client' do
      DeskApi.client.should be_an_instance_of(DeskApi::Client)
    end

    context 'when the options do not change' do
      it 'caches the client' do
        DeskApi.client.should equal(DeskApi.client)
      end
    end

    context 'when the options change' do
      it 'busts the cache' do
        client1 = DeskApi.client
        client1.configure do |config|
          config.username = 'test@example.com'
          config.password = 'password'
        end
        client2 = DeskApi.client
        client1.should_not equal(client2)
      end
    end
  end
end