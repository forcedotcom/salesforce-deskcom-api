# Copyright (c) 2013-2016, Salesforce.com, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#   * Neither the name of Salesforce.com nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'addressable/uri'
require 'desk_api/resource/scrud'
require 'desk_api/resource/pagination'
require 'desk_api/resource/query_params'

module DeskApi
  # {DeskApi::Resource} holds most of the magic of this wrapper. Basically
  # everything that comes back from Desk.com's API is a Resource, it keeps
  # track of all the data, connects you to other resources through links
  # and allows you access to embedded resources.
  #
  # @author    Thomas Stachl <tstachl@salesforce.com>
  # @copyright Copyright (c) 2013-2014 Salesforce.com
  # @license   BSD 3-Clause License
  #
  # @example get a cases {DeskApi::Resource}
  #   cases_resource = DeskApi.cases
  class Resource
    extend Forwardable
    def_delegator :@_client, :by_url, :by_url

    include DeskApi::Resource::SCRUD
    include DeskApi::Resource::QueryParams
    include DeskApi::Resource::Pagination

    class << self
      # Returns a {DeskApi::Resource} definition with a self link
      #
      # @param link [String/Hash] the self href as string or hash
      # @return [Hash]
      def build_self_link(link, params = {})
        link = { 'href' => link } if link.kind_of?(String)
        { '_links' => { 'self' => link } }
      end
    end

    # Initializes a new {DeskApi::Resource} object
    #
    # @param client [DeskApi::Client] the client to be used
    # @param definition [Hash] a defintion for the resource
    # @param loaded [Boolean] indicator of the loading state
    # @return [DeskApi::Resource] the new resource
    def initialize(client, definition = {}, loaded = false)
      reset!
      @_client, @_definition, @_loaded = client, definition, loaded
    end

    # Change self to the next page
    #
    # @return [Desk::Resource] self
    def next!
      load
      next_page = @_definition['_links']['next']

      if next_page
        @_definition = DeskApi::Resource.build_self_link(next_page)
        self.reset!
      end
    end

    # Returns the self link hash
    #
    # @return [Hash] self link hash
    def get_self
      @_definition['_links']['self']
    end

    # Returns the self link href
    #
    # @return [String] self link href
    def href
      get_self['href']
    end
    alias_method :get_href, :href

    # Set the self link href
    #
    # @return [DeskApi::Resource] self
    def href=(value)
      @_definition['_links']['self']['href'] = value
      self
    end

    # Returns a hash based on the current definition of the resource
    #
    # @return [Hash] definition hash
    def to_hash
      load

      {}.tap do |hash|
        @_definition.each do |k, v|
          hash[k] = v
        end
      end
    end

    # Returns the given resource type
    #
    # @return [String] resource type/class
    def resource_type
      get_self['class']
    end

    # Checks if this resource responds to a specific method
    #
    # @param method [String/Symbol]
    # @return [Boolean]
    def respond_to?(method)
      load
      meth = method.to_s

      return true if is_embedded?(meth)
      return true if is_link?(meth)
      return true if meth.end_with?('=') and is_field?(meth[0...-1])
      return true if is_field?(meth)

      super
    end

    # Reloads the current resource
    #
    # @return [DeskApi::Resource] self
    def load!
      self.exec! true
    end
    alias_method :reload!, :load!

    # Only loads the current resource if it isn't loaded yet
    #
    # @return [DeskApi::Resource] self
    def load
      self.exec! unless @_loaded
    end

    # Is the current resource loaded?
    #
    # @return [Boolean]
    def loaded?
      !!@_loaded
    end

    # Executes the request to the Desk.com API if the resource
    # is not loaded yet
    #
    # @param reload [Boolean] should reload the resource
    # @return [DeskApi::Resource] self
    def exec!(reload = false)
      return self if loaded? and !reload
      @_definition, @_loaded = @_client.get(href).body, true
      self
    end

    # Resets a {DeskApi::Resource} to an empty state
    #
    # @return [DeskApi::Resource] self
    def reset!
      @_links, @_embedded, @_changed, @_loaded = {}, {}, {}, false
      self
    end

    private
    attr_accessor :_client, :_loaded, :_changed, :_embedded, :_links, :_definition

    # Checks if the given `method` is a field on the current
    # resource definition
    #
    # @param method [String/Symbol]
    # @return [Boolean]
    def is_field?(method)
      @_definition.key?(method)
    end

    # Checks if the given `method` is a link on the current
    # resource definition
    #
    # @param method [String/Symbol]
    # @return [Boolean]
    def is_link?(method)
      @_definition.key?('_links') and @_definition['_links'].key?(method)
    end

    # Checks if the given `method` is embedded in the current
    # resource definition
    #
    # @param method [String/Symbol]
    # @return [Boolean]
    def is_embedded?(method)
      @_definition.key?('_embedded') and @_definition['_embedded'].key?(method)
    end

    # Returns the field value from the changed or definition hash
    #
    # @param method [String/Symbol]
    # @return [Mixed]
    def get_field_value(method)
      @_changed.key?(method) ? @_changed[method] : @_definition[method]
    end

    # Returns the embedded resource
    #
    # @param method [String/Symbol]
    # @return [DeskApi::Resource]
    def get_embedded_resource(method)
      return @_embedded[method] if @_embedded.key?(method)
      @_embedded[method] = @_definition['_embedded'][method]

      if @_embedded[method].kind_of?(Array)
        @_embedded[method].tap do |ary|
          ary.map!{ |definition| new_resource(definition, true) } unless ary.first.kind_of?(self.class)
        end
      else
        @_embedded[method] = new_resource(@_embedded[method], true)
      end
    end

    # Returns the linked resource
    #
    # @param method [String/Symbol]
    # @return [DeskApi::Resource]
    def get_linked_resource(method)
      return @_links[method] if @_links.key?(method)
      @_links[method] = @_definition['_links'][method]

      if @_links[method] and not @_links[method].kind_of?(self.class)
        @_links[method] = new_resource(self.class.build_self_link(@_links[method]))
      end
    end

    # Creates a new resource
    #
    # @param definition [Hash]
    # @param loaded [Boolean]
    # @param client [DeskApi::Client]
    def new_resource(definition, loaded = false, client = @_client)
      self.class.new(client, definition, loaded)
    end

    # Returns the requested embedded resource, linked resource or field value,
    # also allows to set a new field value
    #
    # @param method [String/Symbol]
    # @param args [Mixed]
    # @param block [Proc]
    # @return [Mixed]
    def method_missing(method, *args, &block)
      load

      meth = method.to_s

      return get_embedded_resource(meth) if is_embedded?(meth)
      return get_linked_resource(meth) if is_link?(meth)
      return @_changed[meth[0...-1]] = args.first if meth.end_with?('=') and is_field?(meth[0...-1])
      return get_field_value(meth) if is_field?(meth)

      super(method, *args, &block)
    end
  end
end
