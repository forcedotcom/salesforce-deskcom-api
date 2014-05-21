module DeskApi::Response
  class ParseJson < Faraday::Response::Middleware
    dependency 'json'

    def on_complete(env)
      env[:body] = ::JSON.parse env[:body] unless env[:body].strip.empty?
    end

  end

  Faraday::Response.register_middleware :desk_parse_json => ParseJson
end
