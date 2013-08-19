module DeskApi
  class Resource
    class Company < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
    end
  end
end