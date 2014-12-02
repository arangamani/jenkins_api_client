#
# Copyright (c) 2012-2013 Kannan Manickam <arangamani.kannan@gmail.com>
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

require 'thor'
require 'json'
require 'thor/group'
require 'terminal-table'

module JenkinsApi
  module CLI
    # This class provides various command line operations for the Node class.
    class Node < Thor
      include Thor::Actions
      include Terminal

      desc "list", "List all nodes"
      method_option :filter, :aliases => "-f",
        :desc => "Regular expression to filter jobs"
      # CLI command that lists all nodes/slaves available in Jenkins or the
      # ones matching the filter provided
      def list
        @client = Helper.setup(parent_options)
        if options[:filter]
          puts @client.node.list(options[:filter])
        else
          puts @client.node.list
        end
      end

      desc "print_general_attributes", "Prints general attributes of nodes"
      # CLI command that prints the general attribtues of nodes
      def print_general_attributes
        @client = Helper.setup(parent_options)
        general_attributes = Client::Node::GENERAL_ATTRIBUTES
        rows = []
        general_attributes.each do |attr|
          rows << [attr, @client.node.method("get_#{attr}").call]
        end
        table = Table.new :headings => ['Attribute', 'Value'], :rows => rows
        puts table
      end

      desc "create_new_node", "create new node"
      # CLI command that creates new node
      option :json
      option :name
      option :slave_host
      option :credentials_id
      option :private_key_file
      option :executors
      option :labels
      def create_new_node
        @client = Helper.setup(parent_options)
        if options[:json]
          json_file = "#{options[:json]}" 
          file = File.read(json_file)
          node_details = JSON.parse(file)
          node_label = node_details['node_label']
          executors = node_details['executors']
          template_detail_hash = node_details['template_detail']
          host_list_array = node_details['host_list']
          host_list_array.each_with_index {|val, index|
          host_name = "#{val}"
          if template_detail_hash['guest_user_credentials_id'] != ""
            credentials_id = template_detail_hash['guest_user_credentials_id']
          else
            puts "failed to find a credentials_id for "+template_detail_hash['guest_username']+"\nPlease add this user in jenkins and #{options[:json]}"
        end
        @client.node.create_dumb_slave(
        :name => host_name,
        :slave_host => host_name,
        :credentials_id => credentials_id,
        :private_key_file => "",
        :executors => executors ? (executors) : (12),
        :labels => node_label)
    }
      elsif options[:name] && options[:credentials_id] && options[:labels]
        @client.node.create_dumb_slave(
        :name => options[:name],
        :slave_host => options[:name],
        :credentials_id => options[:credentials_id],
        :private_key_file => "",
        :executors => options[:executors] ? (options[:executors]) : (12),
        :labels => options[:labels])
      else
        puts "incorrect usage.please see usage of create_new_node in the help menu"

    end
  end

      desc "print_node_attributes NODE", "Prints attributes specific to a node"
      # CLI command to print the attributes specific to a node
      #
      # @param [String] node Name of the node
      #
      def print_node_attributes(node)
        @client = Helper.setup(parent_options)
        node_attributes = Client::Node::NODE_ATTRIBUTES
        rows = []
        node_attributes.each do |attr|
          rows << [attr, @client.node.method("get_node_#{attr}").call(node)]
        end
        table = Table.new :headings => ['Attribute', 'Value'], :rows => rows
        puts "Node: #{node}"
        puts table
      end

      desc "print_node_properties NODE", "Prints properties of a node"
      # CLI command to print the properties of a specific node
      #
      # @param [String] node Name of the node
      #
      def print_node_properties(node)
        @client = Helper.setup(parent_options)
        node_properties = Client::Node::NODE_PROPERTIES
        rows = []
        node_properties.each do |property|
          rows << [property, @client.node.method("is_#{property}?").call(node)]
        end
        table = Table.new :headings => ['Property', 'Value'], :rows => rows
        puts "Node: #{node}"
        puts table
      end

    end
  end
end
