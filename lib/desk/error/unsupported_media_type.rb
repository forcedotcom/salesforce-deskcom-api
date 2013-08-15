require 'desk/error/client_error'

module Desk
  class Error
    # Raised when desk.com returns the HTTP status code 415
    class UnsupportedMediaType < Desk::Error::ClientError
      HTTP_STATUS_CODE = 415
    end
  end
end