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
