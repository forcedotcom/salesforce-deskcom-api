require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 405
    class MethodNotAllowed < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 405
    end
  end
end