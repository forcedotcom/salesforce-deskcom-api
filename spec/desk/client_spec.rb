require 'spec_helper'

describe Desk::Client do
  subject do
    @client ||= Desk::Client.new Desk::CONFIG
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
      Desk.reset!
    end

    context 'with module configuration' do
      before do
        Desk.configure do |config|
          Desk::Configuration.keys.each do |key|
            config.send("#{key}=", @configuration[key])
          end
        end
      end

      it 'inherits the module configuration' do
        client = Desk::Client.new
        Desk::Configuration.keys.each do |key|
          client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
        end
      end
    end

    context 'with class configuration' do
      context "during initialization" do
        it "overrides the module configuration" do
          client = Desk::Client.new(@configuration)
          Desk::Configuration.keys.each do |key|
            client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
          end
        end
      end

      context "after initialization" do
        it "overrides the module configuration after initialization" do
          client = Desk::Client.new
          client.configure do |config|
            @configuration.each do |key, value|
              config.send("#{key}=", value)
            end
          end
          
          Desk::Configuration.keys.each do |key|
            client.instance_variable_get(:"@#{key}").should eq(@configuration[key])
          end
        end
      end
    end

    it 'sets up default resources on client' do
      subject.methods include(:articles, :cases, :companies, :custom_fields, :customers)
      subject.methods include(:filters, :groups, :inbound_mailboxes, :integration_urls)
      subject.methods include(:jobs, :labels, :macros, :rules, :site_settings)
      subject.methods include(:system_message, :topics, :twitter_accounts, :users)
    end
  end

  describe '#get', :vcr do
    it 'fetches resources' do
      response = subject.get('/api/v2/cases/3014')
      response.body.subject.should eq('Testing Quick Case')
    end
  end

  describe '#post', :vcr do
    it 'creates a resource' do
      response = subject.post('/api/v2/topics', @topic_create_data)
      response.body.name.should eq(@topic_create_data[:name])
    end
  end

  describe '#patch', :vcr do
    it 'updates a resource' do
      subject.patch('/api/v2/topics/556402', @topic_update_data).body.name.should eq(@topic_update_data[:name])
    end
  end

  describe '#delete', :vcr do
    it 'deletes a resource' do
      subject.delete('/api/v2/topics/556401').status.should eq(204)
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
      lambda { subject.send(:request, :get, '/path') }.should raise_error(Desk::Error::ClientError)
    end

    it 'catches JSON::ParserError errors' do
      allow(subject).to receive(:connection).and_raise(JSON::ParserError.new('unexpected token'))
      lambda { subject.send(:request, :get, '/path') }.should raise_error(Desk::Error::ParserError)
    end
  end
end