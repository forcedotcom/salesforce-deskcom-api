module Desk
  class Resource
    class Company < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
    end
  end
end