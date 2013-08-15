require 'spec_helper'

describe Desk::Request::Retry do
  subject do
    @client ||= Desk::Client.new Desk::CONFIG
  end

  it 'catches too many requests', vcr: { record: :none} do
    lambda { subject.get('/api/v2/users') }.should raise_error(Desk::Error::TooManyRequests)
  end
end