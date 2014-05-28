require 'desk_api/error'

module DeskApi
  class Error
    # Raised when Desk returns a 5xx HTTP status code
    class ServerError < DeskApi::Error
    end
  end
end
