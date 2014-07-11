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
