module Desk
  class Resource
    class Article < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
      include Desk::Action::Delete
      include Desk::Action::Search
    end
  end
end