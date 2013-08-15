require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 403
    class Forbidden < Desk::Error::ClientError
      HTTP_STATUS_CODE = 403
    end
  end
end