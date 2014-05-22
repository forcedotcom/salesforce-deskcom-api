require 'spec_helper'
require 'desk_api/response/parse_dates'

describe DeskApi::Response::ParseDates do
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
      builder.response :desk_parse_dates
      builder.response :desk_parse_json
      builder.adapter :test, stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'parses iso 8601 strings to time' do
    created_at = @conn.get('http://localhost/echo').body['created_at']
    expect(created_at).to be_instance_of(Time)
    expect(created_at).to eql(Time.parse('2013-12-12T02:55:05Z'))
  end
end
