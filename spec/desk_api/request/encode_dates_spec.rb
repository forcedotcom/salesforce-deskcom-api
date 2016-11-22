# Copyright (c) 2013-2016, Salesforce.com, Inc.
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
require 'desk_api/request/encode_dates'

describe DeskApi::Request::EncodeDates do
  before(:all) do
    VCR.turn_off!

    @stubs = Faraday::Adapter::Test::Stubs.new
    @conn = Faraday.new do |builder|
      builder.request :desk_encode_dates
      builder.request :desk_encode_json
      builder.adapter :test, @stubs
    end
  end

  after(:all) do
    VCR.turn_on!
  end

  it 'encodes the date, datetime and time to iso8601' do
    @stubs.post('/echo') do |env|
      body = JSON.parse(env[:body], symbolize_names: true)
      expect(body[:date]).to eq('2001-02-03T08:00:00Z')
      expect(body[:datetime]).to eq('2001-02-03T00:00:00Z')
      expect(body[:time]).to eq('2001-02-03T08:00:00Z')
    end

    date = Date.new(2001, 2, 3)

    @conn.post('http://localhost/echo', {
      date: date,
      datetime: date.to_datetime,
      time: date.to_time
    })
  end
end
