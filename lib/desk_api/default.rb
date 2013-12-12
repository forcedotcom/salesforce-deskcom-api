module DeskApi::Default
  CONNECTION_OPTIONS = {
    headers: {
      accept: 'application/json',
      user_agent: "desk.com Ruby Gem v#{DeskApi::VERSION}"
    },
    request: {
      open_timeout: 5,
      timeout: 10
    }
  } unless defined? DeskApi::Default::CONNECTION_OPTIONS

  class << self
    # @return [Hash]
    def options
      Hash[DeskApi::Configuration.keys.map{|key| [key, send(key)]}]
    end

    # @return [String]
    def username
      ENV['DESK_USERNAME']
    end

    # @return [String]
    def password
      ENV['DESK_PASSWORD']
    end

    # @return [String]
    def consumer_key
      ENV['DESK_CONSUMER_KEY']
    end

    # @return [String]
    def consumer_secret
      ENV['DESK_CONSUMER_SECRET']
    end

    # @return [String]
    def token
      ENV['DESK_TOKEN']
    end

    # @return [String]
    def token_secret
      ENV['DESK_TOKEN_SECRET']
    end

    # @return [String]
    def subdomain
      ENV['DESK_SUBDOMAIN']
    end

    # @return [String]
    def endpoint
      ENV['DESK_ENDPOINT']
    end

    def connection_options
      CONNECTION_OPTIONS
    end
  end
end