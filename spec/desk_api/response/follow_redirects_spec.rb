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
require 'desk_api/response/follow_redirects'

describe DeskApi::Response::FollowRedirects do
  before do
    VCR.turn_off!

    @body = <<-eos
      <html>
        <body>
        You are being <a href="http://localhost/pong">redirected</a>.
        </body>
      </html>
    eos

    @headers = {
      "accept-ranges"=>"bytes",
      "cache-control"=>"no-cache, private",
      "content-type"=>"text/html; charset=utf-8",
      "date"=>"Mon, 07 Jul 2014 19:34:07 GMT",
      "location"=> "http://localhost/pong",
      "status"=>"302 Found",
      "vary"=>"X-AppVersion",
      "x-appversion"=>"15.99",
      "x-frame-options"=>"SAMEORIGIN",
      "x-rate-limit-limit"=>"300",
      "x-rate-limit-remaining"=>"299",
      "x-rate-limit-reset"=>"53",
      "x-request-id"=>"07f87191096f0ec3e94779020fe76721",
      "content-length"=>"371",
      "connection"=>"Close"
    }

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/301') { [301, @headers, @body] }
      stub.get('/302') { [302, @headers, @body] }
      stub.get('/303') { [303, @headers, @body] }
      stub.get('/307') { [307, @headers, @body] }
      stub.get('/pong') { [200, { 'content-type' => 'application/json' }, "{}"] }

      stub.get('/one') { [302, { 'location' => 'http://localhost/two' }, '']}
      stub.get('/two') { [302, { 'location' => 'http://localhost/three' }, '']}
      stub.get('/three') { [302, { 'location' => 'http://localhost/four' }, '']}
      stub.get('/four') { [302, { 'location' => 'http://localhost/five' }, '']}
      stub.get('/five') { [200, { 'content-type' => 'application/json' }, '{}']}
    end

    @conn = Faraday.new do |builder|
      builder.response :desk_follow_redirects
      builder.adapter :test, stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'redirects to pong' do
    %w(301 302 303 307).each do |status|
      expect(@conn.get("http://localhost/#{status}").env[:url].path).to eq('/pong')
    end
  end

  it 'redirects max 3 times' do
    expect{@conn.get("http://localhost/one")}.to raise_error(DeskApi::Error::FollowRedirectError)
  end
end
