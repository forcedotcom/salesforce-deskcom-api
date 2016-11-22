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

describe DeskApi::Resource::SCRUD do
  subject { @client ||= DeskApi::Client.new DeskApi::CONFIG }

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

    it 'can handle suppress_rules param', skip: 'does not work with VCR' do
      # This test requires a Case Updated rule which always sets case status
      # to open and stops processing if case labels contains
      # 'suppress_rules_test'
      #
      # The case is updated to add the suppress_rules label,
      # the rule will append 'test_failed' if it is run

      VCR.turn_off! ignore_cassettes: true

      ticket = subject.cases.entries.first
      labels = ticket.to_hash['labels']

      ticket.update({
        labels: ['suppress_rules_test'],
        label_action: 'append',
        suppress_rules: true
      })

      expect(ticket.labels.reload!.entries.map(&:name).include?('test_failed')).to be false

      ticket.update({
        labels: labels,
        label_action: 'replace'
      })

      VCR.turn_on!
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

  context '#search' do
    it 'allows searching on search enabled resources', :vcr do
      expect(subject.articles.search(text: 'Lorem Ipsum').total_entries).to eq(0)
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
end
