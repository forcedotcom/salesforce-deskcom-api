require 'desk_api/action/create'
require 'desk_api/action/delete'
require 'desk_api/action/embedded'
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

  protected
    attr_accessor :client, :loaded, :_changed

    def setup(definition)
      setup_links(definition._links) if definition._links?
      setup_fields(definition)
      self
    end

    def exec!(reload = false)
      return self if loaded and !reload
      definition, @loaded = client.get(@_links.self.href).body, true
      setup(definition)
    end

    def method_missing(method, *args, &block)
      self.exec! if !loaded
      raise DeskApi::Error::MethodNotSupported unless self.respond_to?(method.to_sym)
      self.send(method, *args, &block) 
    end
  end
end