require 'spec_helper'

describe DeskApi::Error do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  context '.from_response' do
    it 'can be created from a faraday response', :vcr do
      expect(
        lambda {
          subject.articles.create({ subject: 'Testing', body: 'Testing' })
        }
      ).to raise_error(DeskApi::Error::UnprocessableEntity)
    end

    it 'uses the body message if present', :vcr do
      begin
        subject.articles.create({ subject: 'Testing', body: 'Testing' })
      rescue DeskApi::Error::UnprocessableEntity => e
        expect(e.message).to eq('Validation Failed')
      end
    end
  end

  context 'on validation error' do
    it 'allows access to error hash', :vcr do
      begin
        subject.articles.create({ subject: 'Testing', body: 'Testing' })
      rescue DeskApi::Error::UnprocessableEntity => e
        expect(e.errors).to be_an_instance_of(Hash)
        expect(e.errors).to eq({ _links: { topic: ["blank"]}})
      end
    end
  end
end
