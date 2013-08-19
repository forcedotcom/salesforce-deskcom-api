require 'desk_api/error'

module DeskApi
  class Error
    # Raised when trying to search a resource that doesn't support search
    class MethodNotSupported < DeskApi::Error
    end
  end
end