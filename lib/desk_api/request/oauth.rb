module DeskApi::Request
  class OAuth < Faraday::Middleware
    dependency 'simple_oauth'

    def initialize(app, options)
      super(app)
      @options = options
    end

    def call(env)
      env[:request_headers]['Authorization'] = oauth(env).to_s
      @app.call env
    end

  private
    def oauth(env)
      SimpleOAuth::Header.new env[:method], env[:url].to_s, {}, @options
    end
  end

  Faraday::Request.register_middleware :desk_oauth => OAuth
end
