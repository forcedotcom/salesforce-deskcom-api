module DeskApi::Response
  class ParseDates < Faraday::Response::Middleware
    dependency 'time'
    
    def on_complete(env)
      env[:body] = parse_dates env[:body]
    end

  private

    def parse_dates(value)
      case value
      when Hash
        value.each_pair do |key, element|
          value[key] = parse_dates element
        end
      when Array
        value.each_with_index do |element, index|
          value[index] = parse_dates element
        end
      when /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z\Z/m
        Time.parse value
      else
        value
      end
    end
  end
end
