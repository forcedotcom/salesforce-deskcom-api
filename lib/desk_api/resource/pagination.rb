# Copyright (c) 2013-2017, Salesforce.com, Inc.
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
    # {DeskApi::Resource::Pagination} is responsible for pagination helper
    # methods like `#each_page` or `#all`
    #
    # @author    Thomas Stachl <tstachl@salesforce.com>
    # @copyright Copyright (c) 2013-2017 Salesforce.com
    # @license   BSD 3-Clause License
    #
    # @example search for cases {DeskApi::Resource}
    #   DeskApi.cases.each_page{ |page, num| do_something(page) }
    module Pagination

      # Paginate through all the resources on a give page {DeskApi::Resource}
      #
      # @raise [NoMethodError] if self is not a page resource
      # @raise [ArgumentError] if no block is given
      # @yield [DeskApi::Resource] the current resource
      # @yield [Integer] the current page number
      def all
        raise ArgumentError, "Block must be given for #all" unless block_given?
        each_page do |page, page_num|
          page.entries.each { |resource| yield resource, page_num }
        end
      end

      # Paginate through each page on a give page {DeskApi::Resource}
      #
      # @raise [NoMethodError] if self is not a page resource
      # @raise [ArgumentError] if no block is given
      # @yield [DeskApi::Resource] the current page resource
      # @yield [Integer] the current page number
      def each_page
        raise ArgumentError, "Block must be given for #each_page" unless block_given?

        begin
          page = self.first.per_page(self.query_params['per_page'] || 1000).dup
        rescue NoMethodError => err
          raise NoMethodError, "#each_page and #all are only available on resources which offer pagination"
        end

        begin
          yield page, page.page
        end while page.next!
      end

    end
  end
end
