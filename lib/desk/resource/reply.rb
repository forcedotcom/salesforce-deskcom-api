module Desk
  class Resource
    class Reply < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
    end
  end
end