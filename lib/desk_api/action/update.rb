module DeskApi
  module Action
    module Update
      def update(params = {})
        params.each_pair do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
        setup(client.patch(@_links.self.href, @_changed).body)
      end
    end
  end
end