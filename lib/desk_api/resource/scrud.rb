# Copyright (c) 2013-2018, Salesforce.com, Inc.
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
    # {DeskApi::Resource::SCRUD} handles all the search, create, read, update
    # and delete functionality on the {DeskApi::Resource}
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2018 Salesforce.com
    # @license   BSD 3-Clause License
    #
    # @example search for cases {DeskApi::Resource}
    #   cases = DeskApi.cases.search(subject: 'Test')
    module SCRUD

      # This method will POST to the Desk.com API and create a
      # new resource
      #
      # @param params [Hash] the params to create the resource
      # @return [DeskApi::Resource] the newly created resource
      def create(params = {})
        new_resource(@_client.post(clean_base_url, params).body, true)
      end

      # Use this method to update a {DeskApi::Resource}, it'll
      # PATCH changes to the Desk.com API
      #
      # @param params [Hash] the params to update the resource
      # @return [DeskApi::Resource] the updated resource
      def update(params = {})
        changes = filter_update_actions params
        changes.merge!(filter_links(params)) # quickfix
        changes.merge!(filter_suppress_rules(params)) # another quickfix -- this is getting gross
        params.each_pair{ |key, value| send("#{key}=", value) if respond_to?("#{key}=") }
        changes.merge!(@_changed.clone)

        reset!
        @_definition, @_loaded = [@_client.patch(href, changes).body, true]

        self
      end

      # Deletes the {DeskApi::Resource}.
      #
      # @return [Boolean] has the resource been deleted?
      def delete
        @_client.delete(href).status === 204
      end

      # Using this method allows you to hit the search endpoint
      #
      # @param params [Hash] the search params
      # @return [DeskApi::Resource] the search page resource
      def search(params = {})
        params = { q: params } if params.kind_of?(String)
        url = Addressable::URI.parse(clean_base_url + '/search')
        url.query_values = params
        new_resource(self.class.build_self_link(url.to_s))
      end

      # Returns a {DeskApi::Resource} based on the given id
      #
      # @param id [String/Integer] the id of the resource
      # @param options [Hash] additional options (currently only embed is supported)
      # @return [DeskApi::Resource] the requested resource
      def find(id, options = {})
        res = new_resource(self.class.build_self_link("#{clean_base_url}/#{id}"))

        if options[:embed]
          options[:embed] = [options[:embed]] if !options[:embed].is_a?(Array)
          res.embed(*options[:embed])
        end

        res.exec!
      end
      alias_method :by_id, :find

      protected

      # Returns a clean base url
      #
      # @example removes the search if called from a search resource
      #   '/api/v2/cases/search' => '/api/v2/cases'
      # @example removes the id if your on a specific resource
      #   '/api/v2/cases/1' => '/api/v2/cases'
      # @return [String] the clean base url
      def clean_base_url
        Addressable::URI.parse(href).path.gsub(/\/(search|\d+)$/, '')
      end

      private

      # Filters update actions from the params
      #
      # @see http://dev.desk.com/API/customers/#update
      # @param params [Hash]
      # @return [Hash]
      def filter_update_actions(params = {})
        params.select{ |key, _| key.to_s.include?('_action') }
      end

      # Filters the links
      #
      # @param params [Hash]
      # @return [Hash]
      def filter_links(params = {})
        params.select{ |key, _| key.to_s == '_links' }
      end

      # Filters the suppress_rules param
      #
      # @param params [Hash]
      # @return [Hash]
      def filter_suppress_rules(params = {})
        params.select{ |key, _| key.to_s == 'suppress_rules' }
      end
    end
  end
end
