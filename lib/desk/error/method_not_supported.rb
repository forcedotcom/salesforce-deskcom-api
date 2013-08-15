require 'desk/error'

module Desk
  class Error
    # Raised when trying to search a resource that doesn't support search
    class MethodNotSupported < Desk::Error
    end
  end
end