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

describe DeskApi::Resource do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  context '#initialize' do
    it 'stores the client' do
      expect(subject.articles.instance_variable_get(:@_client)).to eq(subject)
    end

    it 'is not loaded initially' do
      expect(subject.articles.instance_variable_get(:@_loaded)).to eq(false)
    end

    it 'sets up the link to self' do
      expect(subject.articles.href).not_to eq(nil)
    end

    context 'additional options' do
      it 'allows for sorting options' do
        cases = subject.cases(sort_field: :updated_at, sort_direction: :asc)
        expect(cases.href).to eq('/api/v2/cases?sort_direction=asc&sort_field=updated_at')
      end

      it 'allows to specify arbitrary params' do
        expect(subject.cases(company_id: 1).href).to eq('/api/v2/cases?company_id=1')
        expect(subject.cases(customer_id: 1).href).to eq('/api/v2/cases?customer_id=1')
        expect(subject.cases(filter_id: 1).href).to eq('/api/v2/cases?filter_id=1')
      end

      it 'allows to specify embeddables' do
        expect(subject.cases(embed: :customer).href).to eq('/api/v2/cases?embed=customer')
        expect(subject.cases(embed: [:customer, :assigned_user]).href).to eq('/api/v2/cases?embed=customer%2Cassigned_user')
      end

      it 'does not automatically load the resource' do
        expect(subject.cases(company_id: 1).instance_variable_get(:@_loaded)).to eq(false)
      end
    end
  end

  context '#exec!', :vcr do
    it 'loads the current resource' do
      expect(subject.articles.send(:exec!).instance_variable_get(:@_loaded)).to eq(true)
    end

    it 'can be forced to reload' do
      subject.articles.instance_variable_set(:@_loaded, true)
      subject.should_receive(:get).and_call_original
      subject.articles.send(:exec!, true)
    end
  end

  context '#method_missing', :vcr do
    it 'loads the resource to find a suitable method' do
      articles = subject.articles
      articles.instance_variable_set(:@_loaded, false)
      articles.should_receive(:exec!).and_call_original
      articles.entries
    end

    it 'raises an error if method does not exist' do
      expect(lambda { subject.articles.some_other_method }).to raise_error(NoMethodError)
    end
  end

  context '#respond_to', :vcr do
    before do
      @company = DeskApi::Resource.new(subject, {
        '_links' => {'self'=>{'href'=>'/api/v2/cases','class'=>'page'}},
        'name'   => 'foo'
      }, true)
    end

    it 'loads the resource to find a suitable method' do
      @company.instance_variable_set(:@_loaded, false)
      @company.should_receive(:exec!)
      @company.respond_to?(:name)
    end

    it 'returns true if method found in definition' do
      expect(@company.respond_to?(:name)).to eq(true)
    end

    it 'returns false if method does not exist' do
      expect(@company.respond_to?(:no_method_here)).to eq(false)
    end
  end

  context '#by_url', :vcr do
    it 'finds resources by url' do
      expect(subject.articles.by_url('/api/v2/articles/1295677')).to be_an_instance_of(DeskApi::Resource)
    end
  end

  context '#get_self' do
    it 'returns the hash for self' do
      expect(subject.articles.get_self).to eq({
        "href" => "/api/v2/articles"
      })
    end
  end

  context '#href' do
    it 'returns the href for self' do
      expect(subject.articles.href).to eq('/api/v2/articles')
    end

    it 'sets the href' do
      res = DeskApi::Resource.new(subject, {
        '_links'=>{'self'=>{'href'=>'/api/v2/cases'}}
      }, true)

      expect(res.href).to eq('/api/v2/cases')
      res.href = '/api/v2/articles'
      expect(res.href).to eq('/api/v2/articles')
    end
  end

  context '#resource_type' do
    it 'returns the resources type' do
      res = DeskApi::Resource.new(subject, {
        '_links'=>{'self'=>{'href'=>'/api/v2/cases','class'=>'page'}}
      }, true)
      expect(res.resource_type).to eq('page')
    end
  end

  context '#search' do
    it 'allows searching on search enabled resources', :vcr do
      expect(subject.articles.search(text: 'Lorem Ipsum').total_entries).to eq(0)
    end
  end

  context '#create' do
    it 'creates a new topic', :vcr do
      expect(
        topic = subject.topics.create({
          name: 'My new topic'
        }).name
      ).to eq('My new topic')
    end

    it 'throws an error creating a user', :vcr do
      expect(lambda { subject.users.create(name: 'Some User') }).to raise_error(DeskApi::Error::MethodNotAllowed)
    end
  end

  context '#update' do
    it 'updates a topic', :vcr do
      topic = subject.topics.entries.first

      topic.description = 'Some new description'
      topic.update({
        name: 'Updated topic name'
      })

      expect(topic.name).to eq('Updated topic name')
      expect(topic.description).to eq('Some new description')
    end

    it 'throws an error updating a user', :vcr do
      user = subject.users.entries.first
      expect(lambda { user.update(name: 'Some User') }).to raise_error(DeskApi::Error::MethodNotAllowed)
    end

    it 'can update without a hash', :vcr do
      topic = subject.topics.entries.first
      topic.description = 'Another description update.'
      topic.update
      expect(subject.topics.entries.first.description).to eq('Another description update.')
    end

    it 'can handle update action params', :vcr do
      customer  = subject.customers.entries.first
      num_count = customer.phone_numbers.count
      phone     = { type: 'home', value: '(415) 555-1234' }

      customer.update({
        phone_numbers: [phone],
        phone_numbers_update_action: 'append'
      })

      expect(customer.reload!.phone_numbers.size).to eq(num_count + 1)

      customer.update({
        phone_numbers: [phone],
        phone_numbers_update_action: 'append'
      })

      expect(customer.reload!.phone_numbers.size).to eq(num_count + 2)
    end

    it 'can handle action params', :vcr do
      ticket    = subject.cases.entries.first
      num_count = ticket.to_hash['labels'].count
      labels    = ['client_spam', 'client_test']

      ticket.update({
        labels: labels,
        label_action: 'append'
      })

      expect(ticket.labels.reload!.total_entries).to eq(num_count + 2)

      ticket.update({
        labels: labels,
        label_action: 'replace'
      })

      expect(ticket.labels.reload!.total_entries).to eq(2)
    end

    it 'can replace instead of append', :vcr do
      customer  = subject.customers.entries.first
      phone     = { type: 'home', value: '(415) 555-1234' }

      customer.update({
        phone_numbers: [phone, phone, phone],
        phone_numbers_update_action: 'append'
      })

      num_count = customer.reload!.phone_numbers.size
      customer.update({
        phone_numbers: [{ type: 'other', value: '(415) 555-4321' }],
        phone_numbers_update_action: 'replace'
      })

      expect(customer.reload!.phone_numbers.size).to eq(1)
      expect(num_count).not_to eq(customer.phone_numbers.size)
    end

    it 'can handle links', :vcr do
      thomas = { "href"=>"/api/v2/users/16096734", "class"=>"user" }
      andy   = { "href"=>"/api/v2/users/21923785", "class"=>"user" }
      ticket = subject.cases.find(3186)

      ticket.update({
        _links: { assigned_user: thomas }
      })

      expect(ticket.assigned_user.public_name).to eq('Thomas Stachl')
      expect(ticket.load!.assigned_user.public_name).to eq('Thomas Stachl')

      ticket.update({
        _links: { assigned_user: andy }
      })

      expect(ticket.assigned_user.public_name).to eq('Andrew Frauen')
      expect(ticket.load!.assigned_user.public_name).to eq('Andrew Frauen')
    end
  end

  context '#delete' do
    it 'deletes a resource', :vcr do
      expect(
        subject.articles.create({
          subject: 'My subject',
          body: 'Some text for this new article',
          _links: {
            topic: subject.topics.entries.first.get_self
          }
        }).delete
      ).to eq(true)
    end

    it 'throws an error deleting a non deletalbe resource', :vcr do
      user = subject.users.entries.first
      expect(lambda { user.delete }).to raise_error(DeskApi::Error::MethodNotAllowed)
    end
  end

  describe 'embeddable' do
    it 'allows to declare embedds' do
      expect(lambda { subject.cases.embed(:assigned_user) }).not_to raise_error
    end

    it 'changes the url' do
      expect(subject.cases.embed(:assigned_user).href).to eq('/api/v2/cases?embed=assigned_user')
    end

    context 'if you use embed' do
      before do
        VCR.turn_off! ignore_cassettes: true

        @stubs  ||= Faraday::Adapter::Test::Stubs.new
        @client ||= DeskApi::Client.new(DeskApi::CONFIG).tap do |client|
          client.middleware = Proc.new do |builder|
            builder.response :desk_parse_dates
            builder.response :desk_parse_json

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

        first_case = @client.cases.embed(:assigned_user).entries.first
        expect(first_case.assigned_user.name).to eq('Thomas Stachl')
        expect(first_case.assigned_user.instance_variable_get(:@_loaded)).to eq(true)
        expect(times_called).to eq(1)
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
        expect(customer.first_name).to eq('Thomas')
        customer = @client.cases.find(3011, embed: [:customer]).customer
        expect(customer.first_name).to eq('Thomas')
      end
    end
  end

  context '#query_params' do
    before do
      @page = DeskApi::Resource.new(subject, {
        '_links'=>{'self'=>{'href'=>'/api/v2/cases?page=2&per_page=50'}}
      }, true)
    end

    it 'allows to get query params from the current resource' do
      expect(@page.send(:query_params_include?, 'page')).to eq('2')
      expect(@page.send(:query_params_include?, 'per_page')).to eq('50')
    end

    it 'returns nil if param not found' do
      expect(@page.send(:query_params_include?, 'blup')).to eq(nil)
    end
  end

  context '#query_params=' do
    before do
      @page = DeskApi::Resource.new(subject, {
        '_links'=>{'self'=>{'href'=>'/api/v2/cases'}}
      }, true)
    end

    it 'sets query params on the current url' do
      @page.send(:query_params=, { page: 5, per_page: 50 })
      expect(@page.instance_variable_get(:@_definition)['_links']['self']['href']).to eq('/api/v2/cases?page=5&per_page=50')
    end
  end

  context '#get_linked_resource' do
    it 'returns linked resources', :vcr do
      expect(subject.cases.entries.first.customer).to be_an_instance_of(DeskApi::Resource)
    end

    it 'returns nil if link is nil', :vcr do
      expect(subject.articles.next).to eq(nil)
    end

    it 'saves the linked resource instead of the url', :vcr do
      first_case = subject.cases.entries.first
      expect(first_case.customer).to be_an_instance_of(DeskApi::Resource)
      expect(first_case.instance_variable_get(:@_links)['customer']).to be_an_instance_of(DeskApi::Resource)
    end
  end

  context '#page' do
    it 'returns the current page and loads if page not defined', :vcr do
      expect(subject.articles.page).to eq(1)
    end

    it 'sets the page' do
      expect(subject.cases.page(5).page).to eq(5)
    end

    it 'sets the resource to not loaded', :vcr do
      cases = subject.cases.send(:exec!)
      expect(cases.page(5).instance_variable_get(:@_loaded)).to eq(false)
    end

    it 'keeps the resource as loaded', :vcr do
      cases = subject.cases.send(:exec!)
      expect(cases.page(1).instance_variable_get(:@_loaded)).to eq(true)
    end
  end

  context '#find' do
    it 'loads the requested resource', :vcr do
      expect(subject.cases.find(3065).subject).to eq('Testing the Tank again')
    end

    it 'has an alias by_id', :vcr do
      expect(subject.cases.find(3065).subject).to eq('Testing the Tank again')
    end
  end

  context '#to_hash' do
    it 'returns a hash for a desk resource', :vcr do
      expect(subject.topics.entries.first.to_hash).to eq({
        "name" => "Updated topic name",
        "description" => "Another description update.",
        "position" => 1,
        "allow_questions" => true,
        "in_support_center" => true,
        "created_at" => Time.parse("2013-04-22T23:46:42Z"),
        "updated_at" => Time.parse("2014-03-06T17:59:33Z"),
        "_links" => {
          "self" => {
            "href" => "/api/v2/topics/498301",
            "class" => "topic"
          },
          "articles" => {
            "href" => "/api/v2/topics/498301/articles",
            "class" => "article"
          },
          "translations" => {
            "href" => "/api/v2/topics/498301/translations",
            "class" => "topic_translation"
          }
        }
      })
    end

    it 'converts embedded resources to hashes', :vcr do
      path = File.join(
        RSpec.configuration.root_path,
        'stubs',
        'to_hash_embed.json'
      )

      expect(subject.cases(embed: :customer).to_hash.to_json).to eq(
        File.open(path).read
      )
    end
  end

  context '#next!' do
    it 'changes @_definition to next page', :vcr do
      page      = subject.cases.first
      next_page = page.next
      expect(
        page.
          next!.
          instance_variables.
          count { |v| page.instance_variable_get(v) != next_page.instance_variable_get(v) }
      ).to eq(0)
    end

    it 'returns nil on the last page', :vcr do
      expect(subject.cases.last.next!).to eq(nil)
    end

  end

  context '#each_page' do
    it 'iterates over each page', :vcr do
      subject.cases.each_page do |page, page_number|
        expect(page).to be_an_instance_of(DeskApi::Resource)
        expect(page.resource_type).to eq('page')
        expect(page_number).to be_an_instance_of(Fixnum)
      end
    end

    it 'uses a default per_page of 1000', :vcr do
      subject.cases.each_page do |page, page_number|
        expect((page.query_params['per_page'].to_i % 10)).to eq(0)
      end
    end

    it 'uses per_page from query_params if present' do
      subject.cases.per_page(25) do |page, page_number|
        expect(page.query_params['per_page']).to eq(25)
      end
    end

    it 'raises ArgumentError if no block is given' do
      expect { subject.cases.each_page }.to raise_error(ArgumentError)
    end

    it 'raises NoMethodError is called on non-page resources', :vcr do
      expect { subject.cases.entries.first.each_page { |x| x } }.to raise_error(NoMethodError)
    end
  end

  context '#all' do
    it 'iterates over each resource on each page', :vcr do
      subject.cases.all do |resource, page_num|
        expect(resource).to be_an_instance_of(DeskApi::Resource)
        expect(resource.resource_type).to eq('case')
        expect(page_num).to be_an_instance_of(Fixnum)
      end
    end

    it 'raises an argument error if no block is given' do
      expect { subject.cases.all }.to raise_error(ArgumentError)
    end
  end

  context '#reset!' do
    it 'sets @_links, @_embedded, @_changed, and @_loaded to default values', :vcr do
      ticket = subject.cases.embed(:customer).entries.first

      ticket.customer
      ticket.message
      ticket.send(:reset!)

      expect(ticket.instance_variable_get(:@_links)).to eq({})
      expect(ticket.instance_variable_get(:@_embedded)).to eq({})
      expect(ticket.instance_variable_get(:@_changed)).to eq({})
      expect(ticket.instance_variable_get(:@_loaded)).to eq(false)
    end
  end

  context '#load' do
    it 'loads the resource if not already loaded', :vcr do
      tickets = subject.cases
      expect(tickets.instance_variable_get(:@_loaded)).to eq(false)
      tickets.send(:load)
      expect(tickets.instance_variable_get(:@_loaded)).to eq(true)
    end
  end

  context '#loaded?' do
    it 'returns true if the resource is loaded', :vcr do
      tickets = subject.cases
      expect(tickets.send(:loaded?)).to eq(false)
      tickets.send(:load!)
      expect(tickets.send(:loaded?)).to eq(true)
    end
  end

  context '#new_resource' do
    it 'returns a new desk resource from a hash definition' do
      expect(
        subject.
          cases.
          send(:new_resource, DeskApi::Resource.build_self_link('/api/v2/customers'))
      ).to be_an_instance_of(DeskApi::Resource)
    end
  end

  describe 'prioritize links and embeds' do
    before do
      @company = subject.customers.entries.first.company
    end

    it 'returns a desk resource', :vcr do
      expect(@company).to be_an_instance_of(DeskApi::Resource)
    end

    it 'loads the resource and returns the name', :vcr do
      expect(@company.name).to eq('Desk.com')
    end
  end
end
