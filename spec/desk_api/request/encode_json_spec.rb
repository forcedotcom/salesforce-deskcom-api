require 'spec_helper'
require 'desk_api/request/encode_json'

describe DeskApi::Request::EncodeJson do
  before do
    VCR.turn_off!

    @stubs = Faraday::Adapter::Test::Stubs.new
    @conn = Faraday.new do |builder|
      builder.request :desk_encode_json
      builder.adapter :test, @stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'sets the content type header' do
    @stubs.post('/echo') do |env|
      expect(env[:request_headers]).to have_key('Content-Type')
      expect(env[:request_headers]['Content-Type']).to eql('application/json')
    end
    @conn.post('http://localhost/echo', test: 'test')
  end

  it 'encodes the body into json' do
    @stubs.post('/echo') do |env|
      expect(!!JSON.parse(env[:body])).to be_true
    end
    @conn.post('http://localhost/echo', test: 'test')
  end
end
