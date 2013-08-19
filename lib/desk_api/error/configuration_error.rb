require 'desk_api/error'

module DeskApi
  class Error
    class ConfigurationError < ::ArgumentError
    end
  end
end