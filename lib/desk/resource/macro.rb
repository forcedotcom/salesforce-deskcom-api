module Desk
  class Resource
    class Macro < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
      include Desk::Action::Delete
    end
  end
end