require 'desk_api/error'

module DeskApi
  class Error
    # Raised when an updateable resources becomes non-updateable
    # and you try to update it
    class NotUpdateable < DeskApi::Error
    end
  end
end