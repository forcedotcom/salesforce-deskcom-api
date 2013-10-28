require 'spec_helper'

describe DeskApi::Resource do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  describe 'brands' do
    it 'is listable', :vcr do
      subject.brands.should be_instance_of DeskApi::Resource::Page
    end

    it 'is viewable', :vcr do
      subject.brands.first.should be_instance_of DeskApi::Resource
      subject.brands.first.type.should eq 'brand'
    end
  end
end