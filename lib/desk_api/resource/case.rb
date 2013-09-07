module DeskApi
  class Resource
    class Case < DeskApi::Resource
      include DeskApi::Action::Create
      include DeskApi::Action::Update
      include DeskApi::Action::Search

      embeddable :customer, :assigned_user, :assigned_group, :locked_by
    end
  end
end