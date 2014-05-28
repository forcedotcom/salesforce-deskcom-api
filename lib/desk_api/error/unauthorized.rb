require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 401
    class Unauthorized < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 401
    end
  end
end
