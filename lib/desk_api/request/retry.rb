module DeskApi::Request
  class Retry < Faraday::Middleware
    def initialize(app, options = {})
      @max = options[:max] || 3
      @interval = options[:interval] || 10
      super(app)
    end

    def call(env)
      retries   = @max
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
      rescue exception_matcher
        if retries > 0
          retries -= 1
          sleep @interval
          retry
        end
        raise
      end
    end

    def exception_matcher
      exceptions = [Errno::ETIMEDOUT, 'Timeout::Error', Faraday::Error::TimeoutError]
      matcher = Module.new
      (class << matcher; self; end).class_eval do
        define_method(:===) do |error|
          exceptions.any? do |ex|
            if ex.is_a? Module then error.is_a? ex
            else error.class.to_s == ex.to_s
            end
          end
        end
      end
      matcher
    end
  end
end
