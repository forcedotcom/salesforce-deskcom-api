# Copyright (c) 2013-2014, Salesforce.com, Inc.
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

    class << self
      # Returns a {DeskApi::Resource} definition with a self link
      #
      # @param link [String/Hash] the self href as string or hash
      # @return [Hash]
      def build_self_link(link, params = {})
        link = {'href'=>link} if link.kind_of?(String)
        {'_links'=>{'self'=>link}}
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

    # This method will POST to the Desk.com API and create a
    # new resource
    #
    # @param params [Hash] the params to create the resource
    # @return [DeskApi::Resource] the newly created resource
    def create(params = {})
      new_resource(@_client.post(clean_base_url, params).body, true)
    end

    # Use this method to update a {DeskApi::Resource}, it'll
    # PATCH changes to the Desk.com API
    #
    # @param params [Hash] the params to update the resource
    # @return [DeskApi::Resource] the updated resource
    def update(params = {})
      changes = filter_update_actions params
      changes.merge!(filter_links(params)) # quickfix
      params.each_pair{ |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
      changes.merge!(@_changed.clone)

      reset!
      @_definition, @_loaded = [@_client.patch(href, changes).body, true]

      self
    end

    # Deletes the {DeskApi::Resource}.
    #
    # @return [Boolean] has the resource been deleted?
    def delete
      @_client.delete(href).status === 204
    end

    # Using this method allows you to hit the search endpoint
    #
    # @param params [Hash] the search params
    # @return [DeskApi::Resource] the search page resource
    def search(params = {})
      params = { q: params } if params.kind_of?(String)
      url = Addressable::URI.parse(clean_base_url + '/search')
      url.query_values = params
      new_resource(self.class.build_self_link(url.to_s))
    end

    # Returns a {DeskApi::Resource} based on the given id
    #
    # @param id [String/Integer] the id of the resource
    # @param options [Hash] additional options (currently only embed is supported)
    # @return [DeskApi::Resource] the requested resource
    def find(id, options = {})
      res = new_resource(self.class.build_self_link("#{clean_base_url}/#{id}"))
      res.embed(*(options[:embed].kind_of?(Array) ? options[:embed] : [options[:embed]])) if options[:embed]
      res.exec!
    end
    alias_method :by_id, :find

    # Change self to the next page
    #
    # @return [Desk::Resource] self
    def next!
      self.load
      next_page = @_definition['_links']['next']

      if next_page
        @_definition = self.class.build_self_link(next_page)
        self.reset!
      end
    end

    # Paginate through all the resources on a give page {DeskApi::Resource}
    #
    # @raise [NoMethodError] if self is not a page resource
    # @raise [ArgumentError] if no block is given
    # @yield [DeskApi::Resource] the current resource
    # @yield [Integer] the current page number
    def all
      raise ArgumentError, "Block must be given for #all" unless block_given?
      each_page do |page, page_num|
        page.entries.each { |resource| yield resource, page_num }
      end
    end

    # Paginate through each page on a give page {DeskApi::Resource}
    #
    # @raise [NoMethodError] if self is not a page resource
    # @raise [ArgumentError] if no block is given
    # @yield [DeskApi::Resource] the current page resource
    # @yield [Integer] the current page number
    def each_page
      raise ArgumentError, "Block must be given for #each_page" unless block_given?

      begin
        page = self.first.per_page(self.query_params['per_page'] || 1000).dup
      rescue NoMethodError => err
        raise NoMethodError, "#each_page and #all are only available on resources which offer pagination"
      end

      begin
        yield page, page.page
      end while page.next!
    end

    # Allows you to embed/sideload resources
    #
    # @example embed customers with their cases
    #   my_cases = client.cases.embed(:customers)
    # @example embed assigned_user and assigned_group
    #   my_cases = client.cases.embed(:assigned_user, :assigned_group)
    # @param embedds [Symbol/String] whatever you want to embed
    # @return [Desk::Resource] self
    def embed(*embedds)
      # make sure we don't try to embed anything that's not defined
      # add it to the query
      self.tap{ |res| res.query_params = { embed: embedds.join(',') } }
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
      self.load

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


    # Get/set the page and per_page query params
    #
    # @param value [Integer/Nil] the value to use
    # @return [Integer/DeskApi::Resource]
    %w(page per_page).each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(value = nil)
          unless value
            exec! if query_params_include?('#{method}') == nil
            return query_params_include?('#{method}').to_i
          end
          tap{ |res| res.query_params = Hash['#{method}', value.to_s] }
        end
      RUBY
    end

    # Converts the current self href query params to a hash
    #
    # @return [Hash] current self href query params
    def query_params
      Addressable::URI.parse(href).query_values || {}
    end

    # Checks if the specified param is included
    #
    # @param param [String] the param to check for
    # @return [Boolean]
    def query_params_include?(param)
      query_params.include?(param) ? query_params[param] : nil
    end

    # Sets the query params based on the provided hash
    #
    # @param params [Hash] the query params
    # @return [String] the generated href
    def query_params=(params = {})
      return href if params.empty?

      params.keys.each{ |key| params[key] = params[key].join(',') if params[key].is_a?(Array) }

      uri = Addressable::URI.parse(href)
      params = (uri.query_values || {}).merge(params)

      @_loaded = false unless params == uri.query_values

      uri.query_values = params
      self.href = uri.to_s
    end

    # Checks if this resource responds to a specific method
    #
    # @param method [String/Symbol]
    # @return [Boolean]
    def respond_to?(method)
      self.load
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
      @_loaded
    end

    protected

    # Returns a clean base url
    #
    # @example removes the search if called from a search resource
    #   '/api/v2/cases/search' => '/api/v2/cases'
    # @example removes the id if your on a specific resource
    #   '/api/v2/cases/1' => '/api/v2/cases'
    # @return [String] the clean base url
    def clean_base_url
      Addressable::URI.parse(href).path.gsub(/\/(search|\d+)$/, '')
    end

    # Executes the request to the Desk.com API if the resource
    # is not loaded yet
    #
    # @param reload [Boolean] should reload the resource
    # @return [DeskApi::Resource] self
    def exec!(reload = false)
      return self if @_loaded and !reload
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

    # Filters update actions from the params
    #
    # @see http://dev.desk.com/API/customers/#update
    # @param params [Hash]
    # @return [Hash]
    def filter_update_actions(params = {})
      params.select{ |key, _| key.to_s.include?('_action') }
    end

    # Filters the links
    #
    # @param params [Hash]
    # @return [Hash]
    def filter_links(params = {})
      params.select{ |key, _| key.to_s == '_links' }
    end

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
      self.load

      meth = method.to_s

      return get_embedded_resource(meth) if is_embedded?(meth)
      return get_linked_resource(meth) if is_link?(meth)
      return @_changed[meth[0...-1]] = args.first if meth.end_with?('=') and is_field?(meth[0...-1])
      return get_field_value(meth) if is_field?(meth)

      super(method, *args, &block)
    end
  end
end
