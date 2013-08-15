require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 409
    class Conflict < Desk::Error::ClientError
      HTTP_STATUS_CODE = 409
    end
  end
end