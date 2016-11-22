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

describe DeskApi::Resource do
  subject { @client ||= DeskApi::Client.new DeskApi::CONFIG }

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
end
