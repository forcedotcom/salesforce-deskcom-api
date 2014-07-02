require 'spec_helper'
require 'desk_api/request/retry'

describe DeskApi::Request::Retry do
  before do
    VCR.turn_off!

    @stubs = Faraday::Adapter::Test::Stubs.new
    @conn = Faraday.new do |builder|
      builder.request :desk_retry, { interval: 0 }
      builder.adapter :test, @stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'retries three times' do
    times_called = 0

    @stubs.post('/echo') do
      times_called += 1
      raise Faraday::Error::TimeoutError, 'Timeout'
    end

    @conn.post('http://localhost/echo') rescue nil
    expect(times_called).to eq(3)
  end

  it 'retries once if we have too many requests' do
    times_called = 0

    @stubs.post('/echo') do
      times_called += 1
      raise DeskApi::Error::TooManyRequests.from_response({
        body: '{"message":"Too Many Requests"}',
        status: 429,
        response_headers: {
          'status' => 429,
          'x-rate-limit-limit' => '60',
          'x-rate-limit-remaining' => '0',
          'x-rate-limit-reset' => '0',
          'content-length' => '31'
        }
      })
    end

    @conn.post('http://localhost/echo') rescue nil
    expect(times_called).to eq(2)
  end
end
