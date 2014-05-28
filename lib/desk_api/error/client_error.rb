require 'desk_api/error'

module DeskApi
  class Error
    # Raised when desk.com returns a 4xx HTTP status code or there's an error
    # in Faraday
    class ClientError < DeskApi::Error
    end
  end
end
