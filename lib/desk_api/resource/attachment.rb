module DeskApi
  class Resource
    class Attachment < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Delete
    end
  end
end