module DeskApi
  class Resource
    class InboundMailbox < DeskApi::Resource
      embeddable :default_group
    end
  end
end