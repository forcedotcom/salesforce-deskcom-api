require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 405
    class MethodNotAllowed < Desk::Error::ClientError
      HTTP_STATUS_CODE = 405
    end
  end
end