module DeskApi
  class Resource
    class ArticleTranslation < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
    end
  end
end