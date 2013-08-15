module Desk
  class Resource
    class Customer < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
      include Desk::Action::Search
    end
  end
end