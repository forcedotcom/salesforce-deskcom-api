module DeskApi
  module Action
    module Create
      module ClassMethods
        def create(client, path, params)
          self.new(client, client.post(path, params).body)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end