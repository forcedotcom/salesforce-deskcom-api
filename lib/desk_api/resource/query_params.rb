# Copyright (c) 2013-2016, Salesforce.com, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#   * Neither the name of Salesforce.com nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module DeskApi
  class Resource
    # {DeskApi::Resource::QueryParams} specifies all the url query param
    # modifiers.
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2014 Salesforce.com
    # @license   BSD 3-Clause License
    #
    # @example set the per page param {DeskApi::Resource}
    #   first_page = DeskApi.cases.per_page(100)
    module QueryParams

      # Allows you to embed/sideload resources
      #
      # @example embed customers with their cases
      #   my_cases = client.cases.embed(:customers)
      # @example embed assigned_user and assigned_group
      #   my_cases = client.cases.embed(:assigned_user, :assigned_group)
      # @param embedds [Symbol/String] whatever you want to embed
      # @return [Desk::Resource] self
      def embed(*embedds)
        # make sure we don't try to embed anything that's not defined
        # add it to the query
        self.tap{ |res| res.query_params = { embed: embedds.join(',') } }
      end

      # Get/set the page and per_page query params
      #
      # @param value [Integer/Nil] the value to use
      # @return [Integer/DeskApi::Resource]
      %w(page per_page).each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}(value = nil)
            unless value
              exec! if query_params_include?('#{method}') == nil
              return query_params_include?('#{method}').to_i
            end
            tap{ |res| res.query_params = Hash['#{method}', value.to_s] }
          end
        RUBY
      end

      # Converts the current self href query params to a hash
      #
      # @return [Hash] current self href query params
      def query_params
        Addressable::URI.parse(href).query_values || {}
      end

      # Checks if the specified param is included
      #
      # @param param [String] the param to check for
      # @return [Boolean]
      def query_params_include?(param)
        query_params.include?(param) ? query_params[param] : nil
      end

      # Sets the query params based on the provided hash
      #
      # @param params [Hash] the query params
      # @return [String] the generated href
      def query_params=(params = {})
        return href if params.empty?

        params.keys.each{ |key| params[key] = params[key].join(',') if params[key].is_a?(Array) }

        uri = Addressable::URI.parse(href)
        params = (uri.query_values || {}).merge(params)

        @_loaded = false unless params == uri.query_values

        uri.query_values = params
        self.href = uri.to_s
      end
    end
  end
end
