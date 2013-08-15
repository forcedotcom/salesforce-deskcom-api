require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 401
    class Unauthorized < Desk::Error::ClientError
      HTTP_STATUS_CODE = 401
    end
  end
end