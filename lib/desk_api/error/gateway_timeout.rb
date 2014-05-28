require 'desk_api/error/server_error'

module DeskApi
  class Error
    # Raised when Desk returns the HTTP status code 504
    class GatewayTimeout < DeskApi::Error::ServerError
      HTTP_STATUS_CODE = 504
    end
  end
end
