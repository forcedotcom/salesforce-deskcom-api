# Copyright (c) 2013-2014, Salesforce.com, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#   * Neither the name of Salesforce.com nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
require 'desk_api'

# reset environmental variables for tests
ENV['DESK_USERNAME'] = nil
ENV['DESK_PASSWORD'] = nil
ENV['DESK_ENDPOINT'] = nil
ENV['DESK_CONSUMER_KEY'] = nil
ENV['DESK_CONSUMER_SECRET'] = nil
ENV['DESK_TOKEN'] = nil
ENV['DESK_TOKEN_SECRET'] = nil
ENV['DESK_SUBDOMAIN'] = nil

begin
  require_relative '../config'
rescue LoadError
  module DeskApi
    CONFIG = {
      username: 'devel@example.com',
      password: '1234password',
      subdomain: 'devel'
    }

    OAUTH_CONFIG = {
      consumer_key: 'my_consumer_key',
      consumer_secret: 'my_consumer_secret',
      token: 'my_token',
      token_secret: 'my_token_secret',
      subdomain: 'devel'
    }
  end
end

VCR.configure do |config|
  config.hook_into :faraday
  config.cassette_library_dir = 'spec/cassettes'
  config.configure_rspec_metadata!
  config.before_record { |i| i.request.headers.delete('Authorization') }
  config.ignore_request { |request| URI(request.uri).host == 'localhost' }
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.add_setting :root_path, default: File.dirname(__FILE__)
end
