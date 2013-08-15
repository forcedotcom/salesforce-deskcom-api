require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 406
    class NotAcceptable < Desk::Error::ClientError
      HTTP_STATUS_CODE = 406
    end
  end
end