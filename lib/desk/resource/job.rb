module Desk
  class Resource
    class Job < Desk::Resource
      include Desk::Action::Create
    end
  end
end