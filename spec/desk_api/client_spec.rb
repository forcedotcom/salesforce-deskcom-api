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

describe DeskApi::Client do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  before do
    @topic_create_data = { name: 'Test Topic' }
    @topic_update_data = { name: 'Test Updated Topic' }
  end

  context '#initialize' do
    before do
      @configuration = {
        consumer_key: 'CK',
        consumer_secret: 'CS',
        token: 'TOK',
        token_secret: 'TOKS',
        username: 'UN',
        password: 'PW',
        subdomain: 'devel',
        endpoint: 'https://devel.desk.com',
        connection_options: {
          request: { timeout: 10 }
        }
      }
    end

    after do
      DeskApi.reset!
    end

    context 'with module configuration' do
      before do
        DeskApi.configure do |config|
          DeskApi::Configuration.keys.each do |key|
            config.send("#{key}=", @configuration[key])
          end
        end
      end

      it 'inherits the module configuration' do
        client = DeskApi::Client.new
        DeskApi::Configuration.keys.each do |key|
          expect(client.instance_variable_get(:"@#{key}")).to eq(@configuration[key])
        end
      end
    end

    context 'with class configuration' do
      context "during initialization" do
        it "overrides the module configuration" do
          client = DeskApi::Client.new(@configuration)
          DeskApi::Configuration.keys.each do |key|
            expect(client.instance_variable_get(:"@#{key}")).to eq(@configuration[key])
          end
        end
      end

      context "after initialization" do
        it "overrides the module configuration after initialization" do
          client = DeskApi::Client.new
          client.configure do |config|
            @configuration.each do |key, value|
              config.send("#{key}=", value)
            end
          end

          DeskApi::Configuration.keys.each do |key|
            expect(client.instance_variable_get(:"@#{key}")).to eq(@configuration[key])
          end
        end
      end
    end
  end

  context 'using Basic Authentication' do
    describe '#get', :vcr do
      it 'fetches resources' do
        response = subject.get('/api/v2/cases/3014')
        expect(response.body['subject']).to eq('Testing Quick Case')
      end
    end

    describe '#post', :vcr do
      it 'creates a resource' do
        response = subject.post('/api/v2/topics', @topic_create_data)
        expect(response.body['name']).to eq(@topic_create_data[:name])
      end
    end

    describe '#patch', :vcr do
      it 'updates a resource' do
        expect(subject.patch('/api/v2/topics/601117', @topic_update_data).body['name']).to eq(@topic_update_data[:name])
      end
    end

    describe '#delete', :vcr do
      it 'deletes a resource' do
        expect(subject.delete('/api/v2/topics/601117').status).to eq(204)
      end
    end
  end

  context 'using OAuth' do
    before do
      @client = DeskApi::Client.new DeskApi::OAUTH_CONFIG
      @article_create_data = { subject: 'Testing OAuth', body: 'OAuth testing', _links: { topic: { href: '/api/v2/topics/498301' } } }
      @article_update_data = { subject: 'Testing Updated OAuth' }
    end

    describe '#get', :vcr do
      it 'fetches resources' do
        response = @client.get('/api/v2/articles/1391017')
        expect(response.body['subject']).to eq('Testing OAuth')
      end
    end

    describe '#post', :vcr do
      it 'creates a resource' do
        response = @client.post('/api/v2/articles', @article_create_data)
        expect(response.body['subject']).to eq(@article_create_data[:subject])
      end
    end

    describe '#patch', :vcr do
      it 'updates a resource' do
        expect(@client.patch('/api/v2/articles/1391017', @article_update_data).body['subject']).to eq(@article_update_data[:subject])
      end
    end

    describe '#delete', :vcr do
      it 'deletes a resource' do
        expect(@client.delete('/api/v2/articles/1391017').status).to eq(204)
      end
    end
  end

  describe '#by_url', :vcr do
    it 'finds resources by url' do
      expect(subject.by_url('/api/v2/articles/1295677')).to be_an_instance_of(DeskApi::Resource)
    end
  end

  describe '#connection' do
    it 'looks like Faraday connection' do
      expect(subject.send(:connection)).to be_an_instance_of(Faraday::Connection)
    end

    it 'memoizes the connection' do
      c1, c2 = subject.send(:connection), subject.send(:connection)
      expect(c1).to equal(c2)
    end
  end

  describe '#request' do
    it 'catches Faraday errors' do
      allow(subject).to receive(:connection).and_raise(Faraday::Error::ClientError.new('Oops'))
      expect(lambda { subject.send(:request, :get, '/path') }).to raise_error(DeskApi::Error::ClientError)
    end

    it 'catches JSON::ParserError errors' do
      allow(subject).to receive(:connection).and_raise(JSON::ParserError.new('unexpected token'))
      expect(lambda { subject.send(:request, :get, '/path') }).to raise_error(DeskApi::Error::ParserError)
    end
  end
end
