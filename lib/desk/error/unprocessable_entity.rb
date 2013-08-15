require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 422
    class UnprocessableEntity < Desk::Error::ClientError
      HTTP_STATUS_CODE = 422
    end
  end
end