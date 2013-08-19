module DeskApi
  class Resource
    class Job < DeskApi::Resource
      include DeskApi::Action::Create
    end
  end
end