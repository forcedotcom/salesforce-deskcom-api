module DeskApi
  class Resource
    class Reply < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
    end
  end
end