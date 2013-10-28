require 'spec_helper'
require 'desk_api/error/not_updateable'
require 'desk_api/resource/case'

describe DeskApi::Resource::Case do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  it 'is listable', :vcr do
    subject.cases.should be_instance_of DeskApi::Resource::Page
  end

  it 'is viewable', :vcr do
    subject.cases.first.should be_instance_of DeskApi::Resource::Case
  end

  it 'is creatable', :vcr do
    subject.cases.first.should be_kind_of DeskApi::Action::Create
  end

  it 'is updatable', :vcr do
    subject.cases.first.should be_kind_of DeskApi::Action::Update
  end

  it 'is searchable', :vcr do
    subject.cases.first.should be_kind_of DeskApi::Action::Search
  end

  context 'once closed', :vcr do
    before do
      @kase = subject.customers.first.cases.create({
        type: 'phone',
        subject: 'Phone Case Subject',
        priority: 4,
        status: 'closed',
        message: {
          direction: 'in',
          body: 'Example Body'
        }
      })
    end

    it 'can not be updated' do
      lambda { @kase.update(description: 'Testing') }.should raise_error(DeskApi::Error::NotUpdateable)
    end
  end
end