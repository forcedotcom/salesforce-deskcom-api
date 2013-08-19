module DeskApi
  module Action
    module Delete
      def delete
        client.delete(@_links.self.href).status === 204
      end
    end
  end
end