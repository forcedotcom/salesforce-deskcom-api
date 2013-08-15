require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 400
    class BadRequest < Desk::Error::ClientError
      HTTP_STATUS_CODE = 400
    end
  end
end