require 'spec_helper'
require 'desk/request/retry'

describe Desk::Request::Retry do
  before do
    @stubs = Faraday::Adapter::Test::Stubs.new
    @conn = Faraday.new do |builder|
      builder.request :retry, { interval: 0 }
      builder.adapter :test, @stubs
    end
  end

  it 'retries three times', vcr: { record: :none } do
    times_called = 0

    @stubs.post('/echo') do
      times_called += 1
      raise Faraday::Error::TimeoutError, 'Timeout'
    end

    @conn.post('http://localhost/echo') rescue nil
    times_called.should eq(3)
  end

  it 'retries once if we have too many requests', vcr: { record: :none } do
    times_called = 0

    @stubs.post('/echo') do
      times_called += 1
      raise Desk::Error::TooManyRequests.from_response({
        body: '{"message":"Too Many Requests"}',
        status: 429,
        response_headers: {
          'status' => 429,
          'x-rate-limit-limit' => '60',
          'x-rate-limit-remaining' => '0',
          'x-rate-limit-reset' => '1',
          'content-length' => '31'
        }
      })
    end

    @conn.post('http://localhost/echo') rescue nil
    times_called.should eq(2)
  end
end