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
require 'thor/group'
require "#{File.dirname(__FILE__)}/node.rb"
require "#{File.dirname(__FILE__)}/job.rb"
require "#{File.dirname(__FILE__)}/system.rb"

module JenkinsApi
  # This is the base module for all command line interface for Jenkins API.
  #
  module CLI
    # This is the base class for the command line interface which adds other
    # classes as subcommands to the CLI.
    #
    class Base < Thor

      class_option :username, :aliases => "-u", :desc => "Name of Jenkins user"
      class_option :password, :aliases => "-p",
        :desc => "Password of Jenkins user"
      class_option :password_base64, :aliases => "-b",
        :desc => "Base 64 encoded password of Jenkins user"
      class_option :server_ip, :aliases => "-s",
        :desc => "Jenkins server IP address"
      class_option :server_port, :aliases => "-o", :desc => "Jenkins port"
      class_option :creds_file, :aliases => "-c",
        :desc => "Credentials file for communicating with Jenkins server"


      map "-v" => :version

      desc "version", "Shows current version"
      # CLI command that returns the version of Jenkins API Client
      def version
        puts JenkinsApi::Client::VERSION
      end

      # Register the CLI::Node class as "node" subcommand to CLI
      register(
        CLI::Node,
        'node',
        'node [subcommand]',
        'Provides functions to access the node interface of Jenkins CI server'
      )

      # Register the CLI::Job class as "job" subcommand to CLI
      register(
        CLI::Job,
        'job',
        'job [subcommand]',
        'Provides functions to access the job interface of Jenkins CI server'
      )

      # Register the CLI::System class as "system" subcommand to CLI
      register(
        CLI::System,
        'system',
        'system [subcommand]',
        'Provides functions to access system functions of the Jenkins CI server'
      )

    end
  end
end
