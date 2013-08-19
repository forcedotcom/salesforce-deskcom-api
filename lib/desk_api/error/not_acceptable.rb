require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 406
    class NotAcceptable < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 406
    end
  end
end