require 'desk_api/action/create'
require 'desk_api/action/delete'
require 'desk_api/action/embeddable'
require 'desk_api/action/field'
require 'desk_api/action/link'
require 'desk_api/action/resource'
require 'desk_api/action/search'
require 'desk_api/action/update'

require 'desk_api/error/method_not_supported'

module DeskApi
  class Resource
    include DeskApi::Action::Resource
    include DeskApi::Action::Link
    include DeskApi::Action::Field
    include DeskApi::Action::Embeddable

    def initialize(client, definition = {}, loaded = false)
      @client, @loaded, @_changed = client, loaded, {}
      setup(definition)
    end

    def by_url(url)
      definition = client.get(url).body
      resource(definition._links.self['class']).new(client, definition, true)
    end

    def get_self
      @_links.self
    end

    def get_href
      get_self['href']
    end

  protected

    def exec!(reload = false)
      return self if loaded and !reload
      definition, @loaded = client.get(get_href).body, true
      setup(definition)
    end

    def query_params
      Addressable::URI.parse(@_links.self.href).query_values || {}
    end

    def query_params_include?(param)
      query_params.include?(param) ? query_params[param] : nil
    end

    def query_params=(params = {})
      return @_links.self.href if params.empty?

      uri = Addressable::URI.parse(@_links.self.href)
      params = (uri.query_values || {}).merge(params)

      @loaded = false unless params == uri.query_values

      uri.query_values = params
      @_links.self.href = uri.to_s
    end

    def base_class
      self.class
    end

  private
    
    attr_accessor :client, :loaded, :_changed

    def setup(definition)
      setup_links(definition._links) if definition._links?
      setup_embedded(definition._embedded) if definition._embedded?
      setup_fields(definition)
      self
    end

    def method_missing(method, *args, &block)
      self.exec! if !loaded
      raise DeskApi::Error::MethodNotSupported unless self.respond_to?(method.to_sym)
      self.send(method, *args, &block) 
    end
  end
end