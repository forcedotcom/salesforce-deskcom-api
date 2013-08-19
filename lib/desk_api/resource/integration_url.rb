module DeskApi
  class Resource
    class IntegrationUrl < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
      include DeskApi::Action::Delete
    end
  end
end