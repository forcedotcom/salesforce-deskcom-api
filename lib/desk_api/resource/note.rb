module DeskApi
  class Resource
    class Note < DeskApi::Resource
      include DeskApi::Action::Create
    end
  end
end