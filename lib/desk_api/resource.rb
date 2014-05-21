class DeskApi::Resource
  # by_url is deprecated on resources
  extend Forwardable
  def_delegator :@_client, :by_url, :by_url

  class << self
    def build_self_link(link, params = {})
      link = {'href'=>link} if link.kind_of?(String)
      {'_links'=>{'self'=>link}}
    end
  end

  def initialize(client, definition = {}, loaded = false)
    reset!
    @_client, @_definition, @_loaded = client, definition, loaded
    # better default
  end

  def create(params = {})
    self.class.new(@_client, @_client.post(clean_base_url, params).body, true)
  end

  def update(params = {})
    changes       = filter_update_actions params
    params.each_pair{ |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
    changes.merge!(@_changed.clone)
    @_changed     = {}
    @_definition  = @_client.patch(href, changes).body
  end

  def delete
    @_client.delete(href).status === 204
  end

  def search(params = {})
    params = { q: params } if params.kind_of?(String)
    url = Addressable::URI.parse(clean_base_url + '/search')
    url.query_values = params
    self.class.new(@_client, self.class.build_self_link(url.to_s))
  end

  def find(id, options = {})
    res = self.class.new(@_client, self.class.build_self_link("#{clean_base_url}/#{id}"))
    res.embed(*(options[:embed].kind_of?(Array) ? options[:embed] : [options[:embed]])) if options[:embed]
    res.exec!
  end
  alias_method :by_id, :find

  def next!
    self.load
    next_page = @_definition['_links']['next']

    if next_page
      @_definition = self.class.build_self_link(next_page)
      self.reset!
    end

  end

  def all(&block)
    raise ArgumentError, "Block must be given for #all" unless block_given?
    each_page do |page, page_num|
      page.entries.each { |resource| yield resource, page_num }
    end
  end

  def each_page
    raise ArgumentError, "Block must be given for #each_page" unless block_given?
    page = self.first.per_page(self.query_params['per_page'] || 1000).dup
    begin
      yield page, page.page
    end while page.next!
  end


  def embed(*embedds)
    # make sure we don't try to embed anything that's not defined
    # add it to the query
    self.tap{ |res| res.query_params = { embed: embedds.join(',') } }
  end

  def get_self
    @_definition['_links']['self']
  end

  def href
    get_self['href']
  end
  alias_method :get_href, :href

  def href=(value)
    @_definition['_links']['self']['href'] = value
  end

  def to_hash
    self.load

    {}.tap do |hash|
      @_definition.each do |k, v|
        hash[k] = v
      end
    end
  end

  def resource_type
    get_self['class']
  end

  [:page, :per_page].each do |method|
    define_method(method) do |value = nil|
      unless value
        self.exec! if self.query_params_include?(method.to_s) == nil
        return self.query_params_include?(method.to_s).to_i
      end
      self.tap{ |res| res.query_params = Hash[method.to_s, value.to_s] }
    end
  end

  def query_params
    Addressable::URI.parse(href).query_values || {}
  end

  def query_params_include?(param)
    query_params.include?(param) ? query_params[param] : nil
  end

  def query_params=(params = {})
    return href if params.empty?

    params.keys.each{ |key| params[key] = params[key].join(',') if params[key].is_a?(Array) }

    uri = Addressable::URI.parse(href)
    params = (uri.query_values || {}).merge(params)

    @_loaded = false unless params == uri.query_values

    uri.query_values = params
    self.href = uri.to_s
  end

  def respond_to?(method, include_private = false)
    self.load
    meth = method.to_s

    return true if is_embedded?(meth)
    return true if is_link?(meth)
    return true if meth.end_with?('=') and is_field?(meth[0...-1])
    return true if is_field?(meth)

    super
  end

  def reload!
    self.exec! true
  end
  alias_method :load!, :reload!

protected

  def clean_base_url
    Addressable::URI.parse(href).path.gsub(/\/(search|\d+)$/, '')
  end

  def exec!(reload = false)
    return self if @_loaded and !reload
    @_definition, @_loaded = @_client.get(href).body, true
    self
  end

  def reset!
    @_links, @_embedded, @_changed, @_loaded = {}, {}, {}, false
    self
  end

  def load
    self.exec! unless @_loaded
  end

  def loaded?
    @_loaded
  end

private
  attr_accessor :_client, :_loaded, :_changed, :_embedded, :_links, :_definition

  def filter_update_actions(params = {})
    params.select{ |key, _| key.to_s.include?('_action') }
  end

  def is_field?(method)
    @_definition.key?(method)
  end

  def is_link?(method)
    @_definition.key?('_links') and @_definition['_links'].key?(method)
  end

  def is_embedded?(method)
    @_definition.key?('_embedded') and @_definition['_embedded'].key?(method)
  end

  def get_field_value(method)
    @_changed.key?(method) ? @_changed[method] : @_definition[method]
  end

  def get_embedded_resource(method)
    return @_embedded[method] if @_embedded.key?(method)
    @_embedded[method] = @_definition['_embedded'][method]

    if @_embedded[method].kind_of?(Array)
      @_embedded[method].tap do |ary|
        ary.map!{ |definition| self.class.new(@_client, definition, true) } unless ary.first.kind_of?(self.class)
      end
    else
      @_embedded[method] = self.class.new(@_client, @_embedded[method], true)
    end
  end

  def get_linked_resource(method)
    return @_links[method] if @_links.key?(method)
    @_links[method] = @_definition['_links'][method]

    # NOTE: create method for self.class.new
    if @_links[method] and not @_links[method].kind_of?(self.class)
      @_links[method] = self.class.new(@_client, self.class.build_self_link(@_links[method]))
    end
  end

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
