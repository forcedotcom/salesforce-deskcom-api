require 'desk_api/error/not_embeddable'

module DeskApi
  module Action
    module Embeddable
      attr_reader :embedded

      def embed(*embedds)
        # make sure we don't try to embed anything that's not defined
        # add it to the query
        self.query_params = { embed: embedds.each{ |embed|
          unless self.base_class.embeddable?(embed)
            raise DeskApi::Error::NotEmbeddable.new("`#{embed.to_s}' can not be embedded.")
          end
        }.join(',') }
        # return self
        self
      end

      def setup_embedded(embedds)
        if embedds.entries?
          @records = embedds['entries'].map do |record|
            resource(record._links.self['class']).new(client, record, true)
          end 
        else
          embedds.each_pair do |key, definition|
            @_links[key]['resource'] = resource(definition['class']).new @client, definition, true
          end
        end
      end

      module ClassMethods
        def embeddable(*embeddables)
          @embeddables = embeddables
        end

        def embeddable?(key)
          (@embeddables || []).include?(key.to_sym)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end