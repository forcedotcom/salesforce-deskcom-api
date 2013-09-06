require 'spec_helper'
require 'desk_api/error/not_updateable'
require 'desk_api/resource/case'

describe DeskApi::Resource::Case do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
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