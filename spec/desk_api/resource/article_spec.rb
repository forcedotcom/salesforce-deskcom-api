require 'spec_helper'

describe DeskApi::Resource do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  describe 'articles' do
    it 'is listable', :vcr do
      subject.articles.should be_instance_of DeskApi::Resource::Page
    end

    it 'is viewable', :vcr do
      subject.articles.first.should be_instance_of DeskApi::Resource::Article
    end

    it 'is creatable', :vcr do
      subject.articles.first.should be_kind_of DeskApi::Action::Create
    end

    it 'is updatable', :vcr do
      subject.articles.first.should be_kind_of DeskApi::Action::Update
    end

    it 'is deletable', :vcr do
      subject.articles.first.should be_kind_of DeskApi::Action::Delete
    end

    it 'is searchable', :vcr do
      subject.articles.first.should be_kind_of DeskApi::Action::Search
    end
  end
end