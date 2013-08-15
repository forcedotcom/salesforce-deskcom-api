module Desk
  class Resource
    class Note < Desk::Resource
      include Desk::Action::Create
    end
  end
end