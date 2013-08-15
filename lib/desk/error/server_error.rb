require 'desk/error'

module Desk
  class Error
    # Raised when Desk returns a 5xx HTTP status code
    class ServerError < Desk::Error
    end
  end
end