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

      # General attributes of a node.
      # This allows the following methods to be called on this node object.
      # These methods are defined using define_method and are prefixed
      # with get_.
      #
      # def get_busyExecutors
      # def get_displayName
      # def get_totalExecutors
      #
      GENERAL_ATTRIBUTES = [
        "busyExecutors",
        "displayName",
        "totalExecutors"
      ]

      # Properties of a node.
      # The following methods are defined to be called on the node object
      # and are prefixed with is_ and end with ? as they return true or false.
      #
      # def is_idle?(node_name)
      # def is_jnlpAgent?(node_name)
      # def is_launchSupported?(node_name)
      # def is_manualLaunchAllowed?(node_name)
      # def is_offline?(node_name)
      # def is_temporarilyOffline?(node_name)
      #
      NODE_PROPERTIES = [
        "idle",
        "jnlpAgent",
        "launchSupported",
        "manualLaunchAllowed",
        "offline",
        "temporarilyOffline"
      ]

      # Node specific attributes.
      # The following methods are defined using define_method.
      # These methods are prefixed with get_node_.
      #
      # def get_node_numExecutors(node_name)
      # def get_node_icon(node_name)
      # def get_node_displayName(node_name)
      # def get_node_loadStatistics(node_name)
      # def get_node_monitorData(node_name)
      # def get_node_offlineCause(node_name)
      # def get_node_oneOffExecutors(node_name)
      #
      NODE_ATTRIBUTES = [
        "numExecutors",
        "icon",
        "displayName",
        "loadStatistics",
        "monitorData",
        "offlineCause",
        "oneOffExecutors"
      ]

      # Initializes a new node object
      #
      # @param [Object] client reference to Client
      #
      def initialize(client)
        @client = client
      end

      def to_s
        "#<JenkinsApi::Client::Node>"
      end

      # This method lists all nodes
      #
      # @param [String] filter a regex to filter node names
      # @param [Bool] ignorecase whether to be case sensitive or not
      #
      def list(filter = nil, ignorecase = true)
        node_names = []
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each { |computer|
          node_names << computer["displayName"] if computer["displayName"] =~ /#{filter}/i
        }
        node_names
      end

      # Identifies the index of a node name in the array node nodes
      #
      # @param [String] node_name name of the node
      #
      def index(node_name)
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each_with_index { |computer, index|
          return index if computer["displayName"] == node_name
        }
      end

      # Defines methods for general node attributes.
      #
      GENERAL_ATTRIBUTES.each do |meth_suffix|
        define_method("get_#{meth_suffix}") do
          response_json = @client.api_get_request("/computer")
          response_json["#{meth_suffix}"]
        end
      end

      # Defines methods for node properties.
      #
      NODE_PROPERTIES.each do |meth_suffix|
        define_method("is_#{meth_suffix}?") do |node_name|
          response_json = @client.api_get_request("/computer")
          response_json["computer"][index(node_name)]["#{meth_suffix}"] =~ /False/i ? false : true
        end
      end

      # Defines methods for node specific attributes.
      NODE_ATTRIBUTES.each do |meth_suffix|
        define_method("get_node_#{meth_suffix}") do |node_name|
          response_json = @client.api_get_request("/computer")
          response_json["computer"][index(node_name)]["#{meth_suffix}"]
        end
      end

      def change_mode(node_name, mode)
        mode = mode.upcase
        xml = get_config(node_name)
        n_xml = Nokogiri::XML(xml)
        desc = n_xml.xpath("//mode").first
        puts "[DEBUG] Current mode is: #{desc.content}"
        desc.content = "#{mode}"
        xml_modified = n_xml.to_xml
        puts xml_modified
        post_config(node_name, xml_modified)
      end

      def get_config(node_name)
        node_name = "(master)" if node_name == "master"
        @client.get_config("/computer/#{node_name}/config.xml")
      end

      def post_config(node_name, xml)
        node_name = "(master)" if node_name == "master"
        @client.post_config("/computer/#{node_name}/config.xml", xml)
      end

    end
  end
end
