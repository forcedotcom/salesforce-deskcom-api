require 'spec_helper'

describe DeskApi::Resource do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  describe 'account' do
    it 'is viewable', :vcr do
      subject.account.should be_instance_of DeskApi::Resource
      subject.account.type.should eq 'user'
    end
  end
end