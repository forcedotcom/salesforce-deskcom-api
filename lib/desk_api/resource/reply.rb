module DeskApi
  class Resource
    class Reply < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update

      embeddable :case, :sent_by, :entered_by
    end
  end
end