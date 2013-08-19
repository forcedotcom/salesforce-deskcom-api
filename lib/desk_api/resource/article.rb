module DeskApi
  class Resource
    class Article < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
      include DeskApi::Action::Delete
      include DeskApi::Action::Search
    end
  end
end