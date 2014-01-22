module DeskApi
  module Request
    class Retry < Faraday::Request::Retry
      def initialize(app, options = {})
        @max = options[:max] || 3
        @interval = options[:interval] || 10
        super(app)
      end

      def call(env)
        retries   = @retries
        env_clone = env.clone
        begin
          @app.call(env)
        rescue DeskApi::Error::TooManyRequests => e
          if retries > 0 and e.rate_limit.reset_in
            retries = 0
            sleep e.rate_limit.reset_in
            env = env_clone
            retry
          end
          raise
        rescue exception_matcher
          if retries > 0
            retries -= 1
            sleep @interval
            env = env_clone
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

    Faraday.register_middleware :request, retry: lambda { Retry }
  end
end