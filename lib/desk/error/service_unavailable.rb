require 'desk/error/server_error'

module Desk
  class Error
    # Raised when Desk returns the HTTP status code 503
    class ServiceUnavailable < Desk::Error::ServerError
      HTTP_STATUS_CODE = 503
    end
  end
end