module DeskApi::Response
  class ParseJson < Faraday::Response::Middleware
    dependency 'json'

    def on_complete(env)
      content_type = env[:response_headers]['content-type']
      if content_type && content_type.include?('application/json')
        env[:body] = ::JSON.parse env[:body] unless env[:body].strip.empty?
      end
    end
  end
end
