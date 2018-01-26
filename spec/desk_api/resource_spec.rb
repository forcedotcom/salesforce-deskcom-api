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
      expect(subject).to receive(:get).and_call_original
      subject.articles.send(:exec!, true)
    end
  end

  context '#method_missing', :vcr do
    it 'loads the resource to find a suitable method' do
      articles = subject.articles
      articles.instance_variable_set(:@_loaded, false)
      expect(articles).to receive(:exec!).and_call_original
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
      expect(@company).to receive(:exec!)
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
      expect(subject.cases.last.next!).to be_nil
    end

    it 'returns nil on non-page resources', :vcr do
      expect(subject.cases.entries.first.next!).to be_nil
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
