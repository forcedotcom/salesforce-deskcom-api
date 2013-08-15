require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 429
    class TooManyRequests < Desk::Error::ClientError
      HTTP_STATUS_CODE = 429
    end
  end
end