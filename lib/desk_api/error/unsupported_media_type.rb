require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 415
    class UnsupportedMediaType < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 415
    end
  end
end
