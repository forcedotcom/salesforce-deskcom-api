require 'spec_helper'
require 'desk_api/response/raise_error'

describe DeskApi::Response::RaiseError do
  before do
    VCR.turn_off!

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/404'){ [404, {}, ''] }
      stub.get('/502'){ [502, {}, ''] }
    end

    @conn = Faraday.new do |builder|
      builder.response :desk_raise_error, DeskApi::Error::ClientError
      builder.response :desk_raise_error, DeskApi::Error::ServerError
      builder.adapter :test, stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'raises the correct error for client side errors' do
    expect{ @conn.get('http://localhost/404') }.to raise_error(DeskApi::Error::NotFound)
  end

  it 'raises the correct error for server side errors' do
    expect{ @conn.get('http://localhost/502') }.to raise_error(DeskApi::Error::BadGateway)
  end
end
