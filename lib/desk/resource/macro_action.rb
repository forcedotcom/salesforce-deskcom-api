module Desk
  class Resource
    class MacroAction < Desk::Resource
      include Desk::Action::Update
    end
  end
end