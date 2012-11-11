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

require 'thor'
require 'thor/group'
require 'terminal-table'

module JenkinsApi
  module CLI
    class Node < Thor
      include Thor::Actions

      desc "list", "List all nodes"
      method_option :filter, :aliases => "-f", :desc => "Regular expression to filter jobs"
      def list
        @client = Helper.setup(parent_options)
        if options[:filter]
          puts @client.node.list(options[:filter])
        else
          puts @client.node.list
        end
      end

      desc "print_general_attrs", "Prints general attributes of nodes"
      def print_general_attrs
        @client = Helper.setup(parent_options)
        puts @client.node.list.length
      end

      desc "print_node_attrs NODE", "Prints attributes specific to a node"
      def print_node_attributes(node)
        @client = Helper.setup(parent_options)
      end

      desc "print_node_properties NODE", "Prints properties of a node"
      def print_node_properties(node)
        @client = Helper.setup(parent_options)
      end

    end
  end
end
