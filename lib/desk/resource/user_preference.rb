module Desk
  class Resource
    class UserPreference < Desk::Resource
      include Desk::Action::Update
    end
  end
end