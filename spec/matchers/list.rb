require 'rspec/expectations'
require 'desk_api/resource/page'

RSpec::Matchers.define :be_a_list do
  match do |actual|
    actual.instance_of? DeskApi::Resource::Page
  end

  description do
    "be an instance of `DeskApi::Resource::Page`"
  end
end