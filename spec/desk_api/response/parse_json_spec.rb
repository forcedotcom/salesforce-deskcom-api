require 'spec_helper'
require 'desk_api/response/parse_json'

describe DeskApi::Response::ParseJson do
  before do
    VCR.turn_off!

    @xml = <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
      <note>
        <to>Tove</to>
        <from>Jani</from>
        <heading>Reminder</heading>
        <body>Don't forget me this weekend!</body>
      </note>
    eos
    @json = File.open(File.join(RSpec.configuration.root_path, 'stubs', 'article.json')).read

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/json') { [200, { 'content-type' => 'application/json' }, @json] }
      stub.get('/xml') { [200, { 'content-type' => 'application/xml' }, @xml] }
      stub.get('/utf8') { [200, { 'content-type' => 'application/json; charset=utf-8' }, @json] }
    end

    @conn = Faraday.new do |builder|
      builder.response :desk_parse_json
      builder.adapter :test, stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'parses the response body into a hash' do
    body    = @conn.get('http://localhost/json').body
    compare = JSON.parse @json, symbolize_names: true
    expect(body).to be_instance_of(Hash)
    expect(body).to eql(compare)
  end

  it 'looks at the content type header before parsing' do
    body = @conn.get('http://localhost/xml').body
    expect(body).to eql(@xml)
  end

  it 'deals with specified charsets in the content-type header' do
    body = @conn.get('http://localhost/utf8').body
    compare = JSON.parse @json, symbolize_names: true
    expect(body).to be_instance_of(Hash)
    expect(body).to eql(compare)
  end
end
