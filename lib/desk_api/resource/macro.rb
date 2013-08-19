module DeskApi
  class Resource
    class Macro < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
      include DeskApi::Action::Delete
    end
  end
end