require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 403
    class Forbidden < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 403
    end
  end
end