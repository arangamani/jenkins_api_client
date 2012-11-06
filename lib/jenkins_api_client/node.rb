#
# Copyright (c) 2012 Kannan Manickam <arangamani.kannan@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

module JenkinsApi
  class Client
    class Node

      def initialize(client)
        @client = client
      end

      def list_all
        node_names = []
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each { |computer|
          node_names << computer["displayName"]
        }
        node_names
      end

      def list(filter = "^.*")
        node_names = []
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each { |computer|
          node_names << computer["displayName"] if computer["displayName"] =~ /#{filter}/i
        }
        node_names
      end

      def is_offline?(node_name)
        response_json = @client.api_get_request("/computer")
        response_json["computer"]
        #response_json["computer"]["temporarilyOffline"] == "False" ? false : true
      end

      def num_executors(node_name)

      end

      def num_total_executors

      end

    end
  end
end 
