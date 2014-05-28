require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 429
    class TooManyRequests < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 429
    end
  end
end
