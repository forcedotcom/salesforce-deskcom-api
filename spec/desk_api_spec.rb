# Copyright (c) 2013-2016, Salesforce.com, Inc.
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

describe DeskApi do
  describe '.method_missing' do
    it 'delegates config to DeskApi::Client' do
      expect(DeskApi.method_missing(:endpoint)).to be_a(String)
    end

    it 'delegates resource request to DeskApi::Client' do
      expect(DeskApi.method_missing(:cases)).to be_a(DeskApi::Resource)
    end
  end

  describe '.client' do
    it 'should return a client' do
      expect(DeskApi.client).to be_an_instance_of(DeskApi::Client)
    end

    context 'when the options do not change' do
      it 'caches the client' do
        expect(DeskApi.client).to eq(DeskApi.client)
      end
    end

    context 'when the options change' do
      it 'busts the cache' do
        client1 = DeskApi.client
        client1.configure do |config|
          config.username = 'test@example.com'
          config.password = 'password'
        end
        client2 = DeskApi.client
        expect(client1).not_to eq(client2)
      end
    end
  end
end
