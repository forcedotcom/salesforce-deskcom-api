module Desk
  class Resource
    class Attachment < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Delete
    end
  end
end