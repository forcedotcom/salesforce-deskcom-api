module DeskApi
  module Action
    module Link
    private
      attr_accessor :_links
      # Handles the _links part of the HAL response and sets up the associations.
      # It is used by the client to setup the initial resources like `users`, `cases` and
      # so on, as well as by the resource object itself for sub resources (`cases.replies`).
      #
      # @api private
      def setup_links(links)
        @_links = links
        @_links.each_pair do |method, definition|
          (class << self; self; end).send(:define_method, ['first', 'last', 'next', 'previous'].include?(method) ? "#{method}_page" : method) do
            return nil unless definition
            # return the stored resource if we already loaded it
            return @_links[method]['resource'] if @_links[method].key?('resource')
            # this is a really ugly hack but necessary for sub resources which aren't declared consistently
            definition['class'] = 'page' if method.pluralize == method
            # get the client
            client = self.instance_of?(DeskApi::Client) ? self : @client
            # create the new resource
            @_links[method]['resource'] = resource(definition['class']).new client, Hashie::Mash.new({ _links: { self: definition } })
          end
        end
      end
    end
  end
end