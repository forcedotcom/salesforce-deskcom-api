module Desk
  class Resource
    class Case < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
      include Desk::Action::Search
    end
  end
end