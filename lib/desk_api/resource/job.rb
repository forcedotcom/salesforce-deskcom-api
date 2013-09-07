module DeskApi
  class Resource
    class Job < DeskApi::Resource
      include DeskApi::Action::Create
      
      embeddable :user
    end
  end
end