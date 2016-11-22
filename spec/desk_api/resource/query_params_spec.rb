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

describe DeskApi::Resource::QueryParams do
  subject { @client ||= DeskApi::Client.new DeskApi::CONFIG }

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
end
