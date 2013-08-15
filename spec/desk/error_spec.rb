require 'spec_helper'

describe Desk::Error do
  subject do
    @client ||= Desk::Client.new Desk::CONFIG
  end

  context '.from_response' do
    it 'can be created from a faraday response', :vcr do
      lambda {
        subject.articles.create({ subject: 'Testing', body: 'Testing' }) 
      }.should raise_error(Desk::Error::UnprocessableEntity)
    end

    it 'uses the body message if present', :vcr do
      begin
        subject.articles.create({ subject: 'Testing', body: 'Testing' })
      rescue Desk::Error::UnprocessableEntity => e
        e.message.should eq('Validation Failed')
      end
    end
  end
end