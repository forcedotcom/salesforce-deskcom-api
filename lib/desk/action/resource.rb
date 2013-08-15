module Desk
  module Action
    module Resource
    protected
      def resource(name)
        require "desk/resource/#{name}"
        "Desk::Resource::#{name.classify}".constantize
      rescue NameError
      rescue LoadError
        Desk::Resource
      end
    end
  end
end