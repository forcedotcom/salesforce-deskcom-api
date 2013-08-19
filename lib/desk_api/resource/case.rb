module DeskApi
  class Resource
    class Case < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
      include DeskApi::Action::Search
    end
  end
end