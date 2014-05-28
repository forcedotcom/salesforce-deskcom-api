require 'desk_api/error/server_error'

module DeskApi
  class Error
    # Raised when Desk returns the HTTP status code 502
    class BadGateway < DeskApi::Error::ServerError
      HTTP_STATUS_CODE = 502
    end
  end
end
