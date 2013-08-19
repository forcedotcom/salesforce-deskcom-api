require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 400
    class BadRequest < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 400
    end
  end
end