module Desk
  class RateLimit
    def initialize(attrs = {})
      @attrs = attrs
    end
    
    # @return [Integer]
    def limit
      limit = @attrs['x-rate-limit-limit']
      limit.to_i if limit
    end

    # @return [Integer]
    def remaining
      remaining = @attrs['x-rate-limit-remaining']
      remaining.to_i if remaining
    end

    # @return [Integer]
    def reset_in
      reset_in = @attrs['x-rate-limit-reset']
      reset_in.to_i if reset_in
    end
    alias retry_after reset_in
  end
end