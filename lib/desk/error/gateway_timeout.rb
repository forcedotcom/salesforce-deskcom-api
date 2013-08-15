require 'desk/error/server_error'

module Desk
  class Error
    # Raised when Desk returns the HTTP status code 504
    class GatewayTimeout < Desk::Error::ServerError
      HTTP_STATUS_CODE = 504
    end
  end
end