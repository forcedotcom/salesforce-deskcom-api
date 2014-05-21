require 'spec_helper'

describe DeskApi::RateLimit do
  context "#limit" do
    it "returns an Integer when x-rate-limit-limit header is set" do
      rate_limit = DeskApi::RateLimit.new("x-rate-limit-limit" => "150")
      expect(rate_limit.limit).to be_an Integer
      expect(rate_limit.limit).to eq 150
    end

    it "returns nil when x-rate-limit-limit header is not set" do
      rate_limit = DeskApi::RateLimit.new
      expect(rate_limit.limit).to be_nil
    end
  end

  context "#remaining" do
    it "returns an Integer when x-rate-limit-remaining header is set" do
      rate_limit = DeskApi::RateLimit.new("x-rate-limit-remaining" => "149")
      expect(rate_limit.remaining).to be_an Integer
      expect(rate_limit.remaining).to eq 149
    end

    it "returns nil when x-rate-limit-remaining header is not set" do
      rate_limit = DeskApi::RateLimit.new
      expect(rate_limit.remaining).to be_nil
    end
  end

  context "#reset_in" do
    it "returns an Integer when x-rate-limit-reset header is set" do
      rate_limit = DeskApi::RateLimit.new("x-rate-limit-reset" => "36")
      expect(rate_limit.reset_in).to be_an Integer
      expect(rate_limit.reset_in).to eq 36
    end

    it "returns nil when x-rate-limit-reset header is not set" do
      rate_limit = DeskApi::RateLimit.new
      expect(rate_limit.reset_in).to be_nil
    end
  end
end
