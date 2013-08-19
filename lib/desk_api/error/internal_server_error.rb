require 'desk_api/error/server_error'

module DeskApi
  class Error
    # Raised when Desk returns the HTTP status code 500
    class InternalServerError < DeskApi::Error::ServerError
      HTTP_STATUS_CODE = 500
    end
  end
end