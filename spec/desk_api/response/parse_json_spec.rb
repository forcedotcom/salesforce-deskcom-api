require 'spec_helper'
require 'desk_api/response/parse_json'

describe DeskApi::Response::ParseJson do
  before do
    VCR.turn_off!

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/echo') do
        [
          200,
          { 'content-type' => 'application/json' },
          File.open(File.join(RSpec.configuration.root_path, 'stubs', 'article.json')).read
        ]
      end
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
    body    = @conn.get('http://localhost/echo').body
    compare = JSON.parse File.open(File.join(RSpec.configuration.root_path, 'stubs', 'article.json')).read
    expect(body).to be_instance_of(Hash)
    expect(body).to eql(compare)
  end
end
