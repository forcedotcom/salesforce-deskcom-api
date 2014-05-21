require 'faraday'

module DeskApi::Request
  class Retry < Faraday::Request::Retry
    def call(env)
      retries   = @options.max
      request_body = env[:body]
      begin
        env[:body] = request_body
        @app.call(env)
      rescue DeskApi::Error::TooManyRequests => e
        if retries > 0
          retries = 0
          sleep e.rate_limit.reset_in
          retry
        end
        raise
      rescue @errmatch
        if retries > 0
          retries -= 1
          sleep sleep_amount(retries + 1)
          retry
        end
        raise
      end
    end
  end

  Faraday::Request.register_middleware :desk_retry => Retry
end
