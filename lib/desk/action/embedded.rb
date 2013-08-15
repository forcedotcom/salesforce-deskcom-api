module Desk
  module Action
    module Embedded
    protected
      def setup_embedded(entries)
        @records = entries.map do |record|
          resource(record._links.self['class']).new(client, record, true)
        end
      end
    end
  end
end