module Desk
  module Action
    module Search
      module ClassMethods
        def search(client, path)
          client.send(:resource, 'page').new(client, Hashie::Mash.new({ _links: { self: { href: path }}}))
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end