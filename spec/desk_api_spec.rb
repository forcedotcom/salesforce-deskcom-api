require 'spec_helper'

describe DeskApi do
  describe '.method_missing' do
    it 'delegates config to DeskApi::Client' do
      expect(DeskApi.method_missing(:endpoint)).to be_a(String)
    end

    it 'delegates resource request to DeskApi::Client' do
      expect(DeskApi.method_missing(:cases)).to be_a(DeskApi::Resource)
    end
  end

  describe '.client' do
    it 'should return a client' do
      expect(DeskApi.client).to be_an_instance_of(DeskApi::Client)
    end

    context 'when the options do not change' do
      it 'caches the client' do
        expect(DeskApi.client).to eq(DeskApi.client)
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
        expect(client1).not_to eq(client2)
      end
    end
  end
end
