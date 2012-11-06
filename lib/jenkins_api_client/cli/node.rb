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

require "#{File.dirname(__FILE__)}/helper.rb"
module JenkinsApi
  module CLI
    class Node < Thor
      include Thor::Actions
      class_option :username,        :aliases => "-u", :desc => "Name of Jenkins user"
      class_option :password,        :aliases => "-p", :desc => "Password of Jenkins user"
      class_option :password_base64, :aliases => "-b", :desc => "Base 64 encoded password of Jenkins user"
      class_option :server_ip,       :aliases => "-s", :desc => "Jenkins server IP address"
      class_option :server_port,     :aliases => "-o", :desc => "Jenkins server port"
      class_option :creds_file,      :aliases => "-c", :desc => "Credentials file for communicating with Jenkins server"

      desc "list", "List all nodes"
      method_option :filter, :aliases => "-f", :desc => "Regular expression to filter jobs"
      def list
        @client = Helper.setup(options)
        if options[:filter]
          puts @client.node.list(options[:filter])
        else
          puts @client.node.list_all
        end
      end

      #====== test
      desc "is_offline", "is_offline"
      def is_offline(node)
        @client = Helper.setup(options)
        puts @client.node.is_offline?(node)
      end

    end
  end
end

#self.register(
#  Node,
#  'node',
#  'node [subcommand]',
#  'Provides functions to access the node interface of Jenkins CI server'
#)

#end
#end
#end
