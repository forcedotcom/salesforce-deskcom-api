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
          client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
        end
      end
    end

    context 'with class configuration' do
      context "during initialization" do
        it "overrides the module configuration" do
          client = DeskApi::Client.new(@configuration)
          DeskApi::Configuration.keys.each do |key|
            client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
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
            client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
          end
        end
      end
    end
  end

  context 'using Basic Authentication' do
    describe '#get', :vcr do
      it 'fetches resources' do
        response = subject.get('/api/v2/cases/3014')
        response.body['subject'].should eq('Testing Quick Case')
      end
    end

    describe '#post', :vcr do
      it 'creates a resource' do
        response = subject.post('/api/v2/topics', @topic_create_data)
        response.body['name'].should eq(@topic_create_data[:name])
      end
    end

    describe '#patch', :vcr do
      it 'updates a resource' do
        subject.patch('/api/v2/topics/601117', @topic_update_data).body['name'].should eq(@topic_update_data[:name])
      end
    end

    describe '#delete', :vcr do
      it 'deletes a resource' do
        subject.delete('/api/v2/topics/601117').status.should eq(204)
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
        response.body['subject'].should eq('Testing OAuth')
      end
    end

    describe '#post', :vcr do
      it 'creates a resource' do
        response = @client.post('/api/v2/articles', @article_create_data)
        response.body['subject'].should eq(@article_create_data[:subject])
      end
    end

    describe '#patch', :vcr do
      it 'updates a resource' do
        @client.patch('/api/v2/articles/1391017', @article_update_data).body['subject'].should eq(@article_update_data[:subject])
      end
    end

    describe '#delete', :vcr do
      it 'deletes a resource' do
        @client.delete('/api/v2/articles/1391017').status.should eq(204)
      end
    end
  end

  describe '#by_url', :vcr do
    it 'finds resources by url' do
      subject.by_url('/api/v2/articles/1295677').should be_an_instance_of(DeskApi::Resource)
    end
  end

  describe '#connection' do
    it 'looks like Faraday connection' do
      subject.send(:connection).should be_an_instance_of(Faraday::Connection)
    end

    it 'memoizes the connection' do
      c1, c2 = subject.send(:connection), subject.send(:connection)
      c1.should equal(c2)
    end
  end

  describe '#request' do
    it 'catches Faraday errors' do
      allow(subject).to receive(:connection).and_raise(Faraday::Error::ClientError.new('Oops'))
      lambda { subject.send(:request, :get, '/path') }.should raise_error(DeskApi::Error::ClientError)
    end

    it 'catches JSON::ParserError errors' do
      allow(subject).to receive(:connection).and_raise(JSON::ParserError.new('unexpected token'))
      lambda { subject.send(:request, :get, '/path') }.should raise_error(DeskApi::Error::ParserError)
    end
  end
end
