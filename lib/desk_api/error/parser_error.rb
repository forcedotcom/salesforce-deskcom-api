require 'desk_api/error'

module DeskApi
  class Error
    # Raised when JSON parsing fails
    class ParserError < DeskApi::Error
    end
  end
end