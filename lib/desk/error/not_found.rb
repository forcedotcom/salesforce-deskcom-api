require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 404
    class NotFound < Desk::Error::ClientError
      HTTP_STATUS_CODE = 404
    end
  end
end