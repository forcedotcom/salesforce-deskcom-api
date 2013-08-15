require 'spec_helper'

describe Desk do
  describe '.method_missing' do
    it 'delegates to Desk::Client' do
      Desk.method_missing(:endpoint).should be_a(String)
    end
  end

  describe '.respond_to_missing?' do
    it 'delegates to Desk::Client' do
      Desk.respond_to_missing?(:endpoint).should be_true
    end

    it 'takes an optional argument' do
      Desk.respond_to_missing?(:endpoint, true).should be_true
    end
  end

  describe '.client' do
    it 'should return a client' do
      Desk.client.should be_an_instance_of(Desk::Client)
    end

    context 'when the options do not change' do
      it 'caches the client' do
        Desk.client.should equal(Desk.client)
      end
    end

    context 'when the options change' do
      it 'busts the cache' do
        client1 = Desk.client
        client1.configure do |config|
          config.username = 'test@example.com'
          config.password = 'password'
        end
        client2 = Desk.client
        client1.should_not equal(client2)
      end
    end
  end
end