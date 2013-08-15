require 'desk/error/server_error'

module Desk
  class Error
    # Raised when Desk returns the HTTP status code 502
    class BadGateway < Desk::Error::ServerError
      HTTP_STATUS_CODE = 502
    end
  end
end