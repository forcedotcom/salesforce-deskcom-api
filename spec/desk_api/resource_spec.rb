require 'spec_helper'

describe DeskApi::Resource do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  context '#initialize' do
    it 'stores the client' do
      subject.articles.instance_variable_get(:@client).should eq(subject)
    end

    it 'is not loaded initially' do
      subject.articles.instance_variable_get(:@loaded).should be_false
    end

    it 'sets up the link to self' do
      subject.articles.instance_variable_get(:@_links).self.href.should_not be_nil
    end
  end

  context '#exec!', :vcr do
    it 'loads the current resource' do
      subject.articles.send(:exec!).instance_variable_get(:@loaded).should be_true
    end

    it 'can be forced to reload' do
      subject.articles.instance_variable_set(:@loaded, true)
      subject.should_receive(:get).and_call_original
      subject.articles.send(:exec!, true)
    end
  end

  context '#method_missing', :vcr do
    it 'loads the resource to find a suitable method' do
      subject.articles.instance_variable_set(:@loaded, false)
      subject.articles.should_receive(:exec!).and_call_original
      subject.articles.first_page
    end

    it 'raises an error if method does not exist' do
      lambda { subject.articles.some_other_method }.should raise_error(DeskApi::Error::MethodNotSupported)
    end
  end

  context '#by_url', :vcr do
    it 'finds resources by url' do
      subject.articles.by_url('/api/v2/articles/1213277').should be_an_instance_of(DeskApi::Resource::Article)
    end
  end

  context '#get_self' do
    it 'returns the hash for self' do
      subject.articles.get_self.should eq({
        "href" => "/api/v2/articles",
        "class" => "page"
      })
    end
  end

  context '#get_href' do
    it 'returns the href for self' do
      subject.articles.get_href.should eq('/api/v2/articles')
    end
  end

  context '#resource', :vcr do
    it 'requires the specified resource' do
      subject.send(:resource, 'article').should equal(DeskApi::Resource::Article)
    end

    it 'returns the generic resource on error' do
      subject.send(:resource, 'something_crazy').should equal(DeskApi::Resource)
    end
  end

  context '#search' do
    it 'allows searching on search enabled resources', :vcr do
      subject.articles.search(text: 'Lorem Ipsum').total_entries.should eq(0)
    end

    it 'throws an error if search is not enabled' do
      lambda { subject.users.search(test: 'something') }.should raise_error(DeskApi::Error::MethodNotSupported)
    end
  end

  context '#create' do
    it 'creates a new topic', :vcr do
      topic = subject.topics.create({
        name: 'My new topic'
      }).name.should eq('My new topic')
    end

    it 'throws an error creating a user' do
      lambda { subject.users.create(name: 'Some User') }.should raise_error(DeskApi::Error::MethodNotSupported)
    end
  end

  context '#update' do
    it 'updates a topic', :vcr do
      topic = subject.topics.first

      topic.description = 'Some new description'
      topic.update({
        name: 'Updated topic name'
      })

      topic.name.should eq('Updated topic name')
      topic.description.should eq('Some new description')
    end

    it 'throws an error updating a user', :vcr do
      user = subject.users.first
      lambda { user.update(name: 'Some User') }.should raise_error(DeskApi::Error::MethodNotSupported)
    end

    it 'can update without a hash', :vcr do
      topic = subject.topics.first
      topic.description = 'Another description update.'
      topic.update
      subject.topics.first.description.should eq('Another description update.')
    end
  end

  context '#delete' do
    it 'deletes a resource', :vcr do
      subject.articles.create({
        subject: 'My subject',
        body: 'Some text for this new article',
        _links: {
          topic: subject.topics.first.get_self
        }
      }).delete.should be_true
    end

    it 'throws an error deleting a non deletalbe resource', :vcr do
      user = subject.users.first
      lambda { user.delete }.should raise_error(DeskApi::Error::MethodNotSupported)
    end
  end

  describe 'embeddable' do
    it 'has resources defined' do
      DeskApi::Resource::Case.embeddable?(:assigned_user).should be_true
      DeskApi::Resource::Case.embeddable?(:message).should be_false
    end

    it 'allows to declare embedds' do
      lambda { subject.cases.embed(:assigned_user) }.should_not raise_error
      lambda { subject.cases.embed(:message) }.should raise_error(DeskApi::Error::NotEmbeddable)
    end

    it 'changes the url' do
      subject.cases.embed(:assigned_user).get_href.should eq('/api/v2/cases?embed=assigned_user')
    end

    context 'if you use embed' do
      before do
        VCR.turn_off! ignore_cassettes: true

        @stubs  ||= Faraday::Adapter::Test::Stubs.new
        @client ||= DeskApi::Client.new(DeskApi::CONFIG).tap do |client|
          client.middleware = Proc.new do |builder|
            builder.response :mashify
            builder.response :dates
            builder.response :json, content_type: /application\/json/
            builder.adapter :test, @stubs
          end
        end
      end

      after do
        VCR.turn_on!
      end

      it 'does not load the resource again' do
        times_called = 0
        @stubs.get('/api/v2/cases?embed=assigned_user') do
          times_called += 1
          [
            200,
            { 'content-type' => 'application/json' },
            File.open(File.join(RSpec.configuration.root_path, 'stubs', 'cases_embed_assigned_user.json')).read
          ]
        end

        first_case = @client.cases.embed(:assigned_user).first
        first_case.assigned_user.name.should eq('Thomas Stachl')
        first_case.assigned_user.instance_variable_get(:@loaded).should be_true
        times_called.should eq(1)
      end

      it 'can be used in finder' do
        @stubs.get('/api/v2/cases/3011?embed=customer') do
          [
            200,
            { 'content-type' => 'application/json' },
            File.open(File.join(RSpec.configuration.root_path, 'stubs', 'case_embed_customer.json')).read
          ]
        end

        customer = @client.cases.find(3011, embed: :customer).customer
        customer.first_name.should eq('Thomas')
        customer = @client.cases.find(3011, embed: [:customer]).customer
        customer.first_name.should eq('Thomas')
      end
    end
  end
end