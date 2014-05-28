require 'desk_api/error/server_error'

module DeskApi
  class Error
    # Raised when Desk returns the HTTP status code 503
    class ServiceUnavailable < DeskApi::Error::ServerError
      HTTP_STATUS_CODE = 503
    end
  end
end
