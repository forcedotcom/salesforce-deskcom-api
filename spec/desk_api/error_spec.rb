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

describe DeskApi::Error do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  context '.from_response' do
    it 'can be created from a faraday response', :vcr do
      expect(
        lambda {
          subject.articles.create({ subject: 'Testing', body: 'Testing' })
        }
      ).to raise_error(DeskApi::Error::UnprocessableEntity)
    end

    it 'uses the body message if present', :vcr do
      begin
        subject.articles.create({ subject: 'Testing', body: 'Testing' })
      rescue DeskApi::Error::UnprocessableEntity => e
        expect(e.message).to eq('Validation Failed')
      end
    end
  end

  context 'on validation error' do
    it 'allows access to error hash', :vcr do
      begin
        subject.articles.create({ subject: 'Testing', body: 'Testing' })
      rescue DeskApi::Error::UnprocessableEntity => e
        expect(e.errors).to be_an_instance_of(Hash)
        expect(e.errors).to eq({"_links" => { "topic" => ["blank"]}})
      end
    end
  end
end
