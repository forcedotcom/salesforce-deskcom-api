require 'spec_helper'

describe DeskApi::Error do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  context '.from_response' do
    it 'can be created from a faraday response', :vcr do
      lambda {
        subject.articles.create({ subject: 'Testing', body: 'Testing' }) 
      }.should raise_error(DeskApi::Error::UnprocessableEntity)
    end

    it 'uses the body message if present', :vcr do
      begin
        subject.articles.create({ subject: 'Testing', body: 'Testing' })
      rescue DeskApi::Error::UnprocessableEntity => e
        e.message.should eq('Validation Failed')
      end
    end
  end
end