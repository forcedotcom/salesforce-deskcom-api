module Desk
  class Resource
    class ArticleTranslation < Desk::Resource
      include Desk::Action::Create
      include Desk::Action::Update
    end
  end
end