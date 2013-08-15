module Desk
  module Request
    class Retry < Faraday::Request::Retry
      def call(env)
        retries = @retries
        begin
          @app.call(env)
        rescue Desk::Error::TooManyRequests => e
          if retries > 0 and e.rate_limit.reset_in
            retries -= 1
            sleep e.rate_limit.reset_in
          end
          raise
        rescue exception_matcher
          if retries > 0
            retries -= 1
            sleep 10
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