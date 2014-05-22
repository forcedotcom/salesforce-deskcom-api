require 'spec_helper'
require 'desk_api/request/oauth'

describe DeskApi::Request::OAuth do
  before do
    VCR.turn_off!

    @stubs = Faraday::Adapter::Test::Stubs.new
    @conn = Faraday.new do |builder|
      builder.request :desk_oauth, {
        consumer_key: 'consumer_key',
        consumer_secret: 'consumer_secret',
        token: 'token',
        token_secret: "token_secret"
      }
      builder.adapter :test, @stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'sets the authorization header' do
    @stubs.post('/echo') do |env|
      expect(env[:request_headers]).to have_key('Authorization')
      expect(env[:request_headers]['Authorization']).to include('OAuth')
    end
    @conn.post('http://localhost/echo')
  end
end
