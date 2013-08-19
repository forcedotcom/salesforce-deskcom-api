module DeskApi
  class Resource
    class Page < DeskApi::Resource
      include Enumerable
      include DeskApi::Action::Embedded

      [
        :all?, :any?,
        :collect, :each, :entries, :find, :find_all,
        :find_index, :first, :first, :group_by, :last,
        :map, :map!, :none?, :one?, :partition, :reduce,
        :reject, :select, :sort, :sort_by, :taken, :zip
      ].each do |method|
        define_method(method) do |*args, &block|
          exec!.records.send(method, *args, &block)
        end
      end

      def search(params)
        raise DeskApi::Error::MethodNotSupported unless base_class.respond_to?(:search)
        url = Addressable::URI.parse(clean_base_url + '/search')
        url.query_values = params
        base_class.search(client, url.to_s).exec!
      end

      def create(params)
        raise DeskApi::Error::MethodNotSupported unless base_class.respond_to?(:create)
        base_class.create(client, clean_base_url, params)
      end

      [:page, :per_page].each do |method|
        define_method(method) do |value = nil|
          if not value
            self.exec! if self.query_params(method.to_s) == nil
            return self.query_params(method.to_s).to_i
          end
          self.query_params = Hash[method.to_s, value.to_s]
          self
        end
      end

      def by_id(id)
        by_url("#{clean_base_url}/#{id}")
      end

    protected
    
      attr_reader :records

      def setup(definition)
        setup_embedded(definition._embedded['entries']) if definition._embedded?
        super(definition)
      end

      def query_params(param)
        params = Addressable::URI.parse(@_links.self.href).query_values || {}
        params.include?(param) ? params[param] : nil
      end

      def query_params=(params = {})
        return @_links.self.href if params.empty?

        uri = Addressable::URI.parse(@_links.self.href)
        params = (uri.query_values || {}).merge(params)

        @loaded = false unless params == uri.query_values

        uri.query_values = params
        @_links.self.href = uri.to_s
      end

      def clean_base_url
        Addressable::URI.parse(@_links.self.href).path.gsub(/\/search$/, '') 
      end

      def base_class
        resource(clean_base_url[/\w+$/].singularize)
      end
    end
  end
end