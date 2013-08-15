module Desk
  module Action
    module Field
    protected
      # Handles the _links part of the HAL response and sets up the associations.
      # It is used by the client to setup the initial resources like `users`, `cases` and
      # so on, as well as by the resource object itself for sub resources (`cases.replies`).
      #
      # @api private
      def setup_fields(definition)
        definition.each_pair do |key, value|
          next if key[0] == '_'
          # set the instance variable
          instance_variable_set(:"@#{key}", value)
          # create getter
          (class << self; self; end).send(:define_method, "#{key}") do
            return @_changed[key] if kind_of?(Desk::Action::Update) and @_changed[key]
            instance_variable_get(:"@#{key}")
          end
          # create setter
          if kind_of?(Desk::Action::Update)
            (class << self; self; end).send(:define_method, "#{key}=") do |value|
              if instance_variable_get(:"@#{key}") != value
                @_changed[key] = value
              end
              self
            end
          end
        end
      end
    end
  end
end