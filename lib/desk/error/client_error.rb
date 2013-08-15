require 'desk/error'

module Desk
  class Error
    # Raised when desk.com returns a 4xx HTTP status code or there's an error in Faraday
    class ClientError < Desk::Error
    end
  end
end