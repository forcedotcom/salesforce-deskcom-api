require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 409
    class Conflict < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 409
    end
  end
end
