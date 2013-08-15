require 'desk/error'

module Desk
  class Error
    # Raised when JSON parsing fails
    class ParserError < Desk::Error
    end
  end
end