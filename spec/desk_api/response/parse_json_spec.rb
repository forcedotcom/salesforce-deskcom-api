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

require 'spec_helper'
require 'desk_api/response/parse_json'

describe DeskApi::Response::ParseJson do
  before do
    VCR.turn_off!

    @xml = <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
      <note>
        <to>Tove</to>
        <from>Jani</from>
        <heading>Reminder</heading>
        <body>Don't forget me this weekend!</body>
      </note>
    eos
    @json = File.open(File.join(RSpec.configuration.root_path, 'stubs', 'article.json')).read

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/json') { [200, { 'content-type' => 'application/json' }, @json] }
      stub.get('/xml') { [200, { 'content-type' => 'application/xml' }, @xml] }
      stub.get('/utf8') { [200, { 'content-type' => 'application/json; charset=utf-8' }, @json] }
    end

    @conn = Faraday.new do |builder|
      builder.response :desk_parse_json
      builder.adapter :test, stubs
    end
  end

  after do
    VCR.turn_on!
  end

  it 'parses the response body into a hash' do
    body    = @conn.get('http://localhost/json').body
    compare = JSON.parse @json
    expect(body).to be_instance_of(Hash)
    expect(body).to eql(compare)
  end

  it 'looks at the content type header before parsing' do
    body = @conn.get('http://localhost/xml').body
    expect(body).to eql(@xml)
  end

  it 'deals with specified charsets in the content-type header' do
    body = @conn.get('http://localhost/utf8').body
    compare = JSON.parse @json
    expect(body).to be_instance_of(Hash)
    expect(body).to eql(compare)
  end
end
