class DeskApi::Resource
  class << self
    def build_self_link(link, params = {})
      link = {'href'=>link} if link.kind_of?(String)
      {'_links'=>{'self'=>link}}
    end
  end

  def initialize(client, definition = {}, loaded = false)
    @_client, @_definition, @_loaded, @_changed = client, definition, loaded, {}
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

  def embed(*embedds)
    # make sure we don't try to embed anything that's not defined
    # add it to the query
    self.tap{ |res| res.query_params = { embed: embedds.join(',') } }
  end

  def by_url(url)
    self.class.new(@_client, self.class.build_self_link(url))
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
    self.exec! unless @_loaded
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

protected

  def clean_base_url
    Addressable::URI.parse(href).path.gsub(/\/(search|\d+)$/, '')
  end

  def exec!(reload = false)
    return self if @_loaded and !reload
    @_definition, @_loaded = @_client.get(href).body, true
    self
  end

private
  attr_accessor :_client, :_loaded, :_changed, :_definition

  def filter_update_actions(params = {})
    params.select{ |key, _| key.to_s.include?('update_action') }
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
    embedds = @_definition['_embedded']

    if embedds[method].kind_of?(Array) and not embedds[method].first.kind_of?(self.class)
      embedds[method].map!{ |definition| self.class.new(@_client, definition, true) }
    elsif not embedds[method].kind_of?(self.class)
      embedds[method] = self.class.new(@_client, embedds[method], true)
    else
      embedds[method]
    end
  end

  def get_linked_resource(method)
    links = @_definition['_links']

    return nil if links[method].nil?
    return links[method] if links[method].kind_of?(self.class)

    links[method] = self.class.new(@_client, self.class.build_self_link(links[method]))
  end

  def method_missing(method, *args, &block)
    self.exec! unless @_loaded

    meth = method.to_s

    return get_embedded_resource(meth) if is_embedded?(meth)
    return get_linked_resource(meth) if is_link?(meth)
    return @_changed[meth[0...-1]] = args.first if meth.end_with?('=') and is_field?(meth[0...-1])
    return get_field_value(meth) if is_field?(meth)

    super(method, *args, &block)
  end
end
