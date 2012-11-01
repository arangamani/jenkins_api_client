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
require 'terminal-table/import'
require "#{File.dirname(__FILE__)}/client.rb"

module JenkinsApi

  class CLI < Thor
    def initialize(args=[], options={}, config={})
      super(args, options, config)
    end
  end

  class Job < Thor

    desc "list", "List jobs"
    method_option :filter, :aliases => "-f", :desc => "Regular expression to filter jobs"
    def list
      @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))
      if options[:filter]
        puts @client.job.list(options[:filter])
      else
        puts @client.job.list_all
      end
    end

    desc "build JOB", "Build a job"
    def build(job)
      @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))
      @client.job.build(job)
    end

    desc "status JOB", "Get the current build status of a job"
    def status(job)
      @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))
      puts @client.job.get_current_build_status(job)
    end

    desc "listrunning", "List running jobs"
    def listrunning
      @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))
      puts @client.job.list_running
    end

  end
end

JenkinsApi::CLI.register(
  JenkinsApi::Job,
  'job',
  'job [subcommand]',
  'provides functions to access the job interface of Jenkins CI server'
)

