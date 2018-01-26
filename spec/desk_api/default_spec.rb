# Copyright (c) 2013-2018, Salesforce.com, Inc.
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

require 'spec_helper'

describe DeskApi::Default do
  context '#options' do
    it 'returns a hash with mostly nil values' do
      expect(DeskApi::Default.options).to eq({
        consumer_key: nil,
        consumer_secret: nil,
        token: nil,
        token_secret: nil,
        username: nil,
        password: nil,
        subdomain: nil,
        endpoint: nil,
        connection_options: {
          headers: {
            accept: 'application/json',
            user_agent: "desk.com Ruby Gem v#{DeskApi::VERSION}"
          },
          request: {
            open_timeout: 5,
            timeout: 10
          }
        }
      })
    end

    it 'returns a hash with environmental variables' do
      ENV['DESK_CONSUMER_KEY'] = 'CK'
      ENV['DESK_CONSUMER_SECRET'] = 'CS'
      ENV['DESK_TOKEN'] = 'TOK'
      ENV['DESK_TOKEN_SECRET'] = 'TOKS'
      ENV['DESK_USERNAME'] = 'UN'
      ENV['DESK_PASSWORD'] = 'PW'
      ENV['DESK_SUBDOMAIN'] = 'SD'
      ENV['DESK_ENDPOINT'] = 'EP'

      expect(DeskApi::Default.options).to eq({
        consumer_key: 'CK',
        consumer_secret: 'CS',
        token: 'TOK',
        token_secret: 'TOKS',
        username: 'UN',
        password: 'PW',
        subdomain: 'SD',
        endpoint: 'EP',
        connection_options: {
          headers: {
            accept: 'application/json',
            user_agent: "desk.com Ruby Gem v#{DeskApi::VERSION}"
          },
          request: {
            open_timeout: 5,
            timeout: 10
          }
        }
      })

      ENV['DESK_CONSUMER_KEY'] = nil
      ENV['DESK_CONSUMER_SECRET'] = nil
      ENV['DESK_TOKEN'] = nil
      ENV['DESK_TOKEN_SECRET'] = nil
      ENV['DESK_USERNAME'] = nil
      ENV['DESK_PASSWORD'] = nil
      ENV['DESK_SUBDOMAIN'] = nil
      ENV['DESK_ENDPOINT'] = nil
    end
  end
end
