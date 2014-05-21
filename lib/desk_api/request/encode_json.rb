module DeskApi::Request
  class EncodeJson < Faraday::Middleware
    dependency 'json'

    def call(env)
      env[:request_headers]['Content-Type'] = 'application/json'
      env[:body] = ::JSON.dump(env[:body]) if env[:body] and not env[:body].to_s.empty?
      @app.call env
    end
  end
end
