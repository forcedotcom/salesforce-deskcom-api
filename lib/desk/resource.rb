require 'desk/action/create'
require 'desk/action/delete'
require 'desk/action/embedded'
require 'desk/action/field'
require 'desk/action/link'
require 'desk/action/resource'
require 'desk/action/search'
require 'desk/action/update'

require 'desk/error/method_not_supported'

module Desk
  class Resource
    include Desk::Action::Resource
    include Desk::Action::Link
    include Desk::Action::Field

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
      raise Desk::Error::MethodNotSupported unless self.respond_to?(method.to_sym)
      self.send(method, *args, &block) 
    end
  end
end