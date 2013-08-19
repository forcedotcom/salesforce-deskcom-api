require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/spec/'
  add_filter 'config.rb'
end

require 'rspec'
require 'vcr'
require 'desk'

begin
  require_relative '../config'
rescue LoadError
  module DeskApi
    CONFIG = {
      username: 'devel@example.com',
      password: '1234password',
      subdomain: 'devel'
    }
  end
end

VCR.configure do |config|
  config.hook_into :typhoeus, :faraday
  config.cassette_library_dir = 'spec/cassettes'
  config.configure_rspec_metadata!
  config.before_record { |i| i.request.headers.delete('Authorization') }
  config.ignore_request { |request| URI(request.uri).host == 'localhost' }
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end