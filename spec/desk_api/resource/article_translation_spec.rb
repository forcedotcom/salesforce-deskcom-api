require 'spec_helper'

describe DeskApi::Resource do
  subject do
    @client ||= DeskApi::Client.new DeskApi::CONFIG
  end

  describe 'article translations' do
    it 'is listable', :vcr do
      subject.articles.first.translations.should be_instance_of DeskApi::Resource::Page
    end

    it 'is viewable', :vcr do
      subject.articles.first.translations.first.should be_instance_of DeskApi::Resource::ArticleTranslation
    end

    it 'is creatable', :vcr do
      subject.articles.first.translations.first.should be_kind_of DeskApi::Action::Create
    end

    it 'is updatable', :vcr do
      subject.articles.first.translations.first.should be_kind_of DeskApi::Action::Update
    end
  end
end