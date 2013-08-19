module DeskApi
  class Resource
    class TopicTranslation < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
      include DeskApi::Action::Delete
    end
  end
end