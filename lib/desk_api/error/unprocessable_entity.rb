require 'desk_api/error/client_error'

module DeskApi
  class Error
    # Raised when desk.com returns the HTTP status code 422
    class UnprocessableEntity < DeskApi::Error::ClientError
      HTTP_STATUS_CODE = 422
      attr_reader :errors
    end
  end
end
