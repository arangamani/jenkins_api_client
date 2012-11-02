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

require File.expand_path('../base', __FILE__)
require 'fileutils'

module JenkinsApi
  module CLI

    class Job < Thor
      include Thor::Actions
      class_option :username,        :aliases => "-u", :desc => "Name of Jenkins user"
      class_option :password,        :aliases => "-p", :desc => "Password of Jenkins user"
      class_option :password_base64, :aliases => "-b", :desc => "Base 64 encoded password of Jenkins user"
      class_option :server_ip,       :aliases => "-s", :desc => "Jenkins server IP address"
      class_option :server_port,     :aliases => "-o", :desc => "Jenkins server port"
      class_option :creds_file,      :aliases => "-c", :desc => "Credentials file for communicating with Jenkins server"

      no_tasks {
        def setup
          if options[:username] && options[:server_ip] && (options[:password] || options[:password_base64])
            creds = options
          elsif options[:creds_file]
            creds = YAML.load_file(File.expand_path(options[:creds_file], __FILE__))
          elsif File.exist?("#{ENV['HOME']}/.jenkins_api_client/login.yml")
            creds = YAML.load_file(File.expand_path("#{ENV['HOME']}/.jenkins_api_client/login.yml", __FILE__))
          else
            say "Credentials are not set. Please pass them as parameters or set them in the default credentials file", :red
          end
           JenkinsApi::Client.new(creds)
        end
      }

      desc "test", "Test job"
      def test
        #invoke :creds
        setup
        puts "test: #{options[:username]}"
        #puts self.options[:username] if self.options[:username]
      end

      desc "list", "List jobs"
      method_option :filter, :aliases => "-f", :desc => "Regular expression to filter jobs"
      def list
        @client = setup
        if options[:filter]
          puts @client.job.list(options[:filter])
        else
          puts @client.job.list_all
        end
      end

      desc "build JOB", "Build a job"
      def build(job)
        @client = setup
        @client.job.build(job)
      end

      desc "status JOB", "Get the current build status of a job"
      def status(job)
        @client = setup
        puts @client.job.get_current_build_status(job)
      end

      desc "listrunning", "List running jobs"
      def listrunning
        @client =  setup
        puts @client.job.list_running
      end

    end
  end
end
