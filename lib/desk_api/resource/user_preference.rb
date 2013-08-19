module DeskApi
  class Resource
    class UserPreference < DeskApi::Resource
      include DeskApi::Action::Update
    end
  end
end