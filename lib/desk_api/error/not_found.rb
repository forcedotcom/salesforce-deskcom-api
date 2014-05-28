require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 404
    class NotFound < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 404
    end
  end
end
