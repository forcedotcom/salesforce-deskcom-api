module DeskApi
  class Resource
    class Filter < DeskApi::Resource
      embeddable :user, :group
    end
  end
end