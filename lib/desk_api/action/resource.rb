module DeskApi
  module Action
    module Resource
    private
      def resource(name)
        require "desk_api/resource/#{name}"
        "DeskApi::Resource::#{name.classify}".constantize
      rescue NameError
      rescue LoadError
        DeskApi::Resource
      end
    end
  end
end