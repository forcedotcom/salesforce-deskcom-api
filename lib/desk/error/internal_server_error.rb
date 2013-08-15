require 'desk/error/server_error'

module Desk
  class Error
    # Raised when Desk returns the HTTP status code 500
    class InternalServerError < Desk::Error::ServerError
      HTTP_STATUS_CODE = 500
    end
  end
end