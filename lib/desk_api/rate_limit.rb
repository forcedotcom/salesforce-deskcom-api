module DeskApi
  # {DeskApi::RateLimit} deciphers rate limiting headers in
  # responses from desk.com API.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2014 Thomas Stachl
  # @license   MIT
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
    alias_method :retry_after, :reset_in
  end
end
