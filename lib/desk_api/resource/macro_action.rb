module DeskApi
  class Resource
    class MacroAction < DeskApi::Resource
      include DeskApi::Action::Update
    end
  end
end