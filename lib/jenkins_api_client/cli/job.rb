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

module JenkinsApi
  module CLI

    class Job < Thor
      include Thor::Actions

      desc "list", "List jobs"
      method_option :status, :aliases => "-t", :desc => "Status to filter"
      method_option :filter, :aliases => "-f", :desc => "Regular expression to filter jobs"
      def list
        @client = Helper.setup(parent_options)
        if options[:filter] && options[:status]
          name_filtered = @client.job.list(options[:filter])
          puts @client.job.list_by_status(options[:status], name_filtered)
        elsif options[:filter]
          puts @client.job.list(options[:filter])
        elsif options[:status]
          puts @client.job.list_by_status(options[:status])
        else
          puts @client.job.list_all
        end
      end

      desc "recreate JOB", "Recreate a specified job"
      def recreate(job)
        @client = Helper.setup(parent_options)
        @client.job.recreate(job)
      end

      desc "build JOB", "Build a job"
      def build(job)
        @client = Helper.setup(parent_options)
        @client.job.build(job)
      end

      desc "status JOB", "Get the current build status of a job"
      def status(job)
        @client = Helper.setup(parent_options)
        puts @client.job.get_current_build_status(job)
      end

      desc "listrunning", "List running jobs"
      def listrunning
        @client =  Helper.setup(parent_options)
        puts @client.job.list_running
      end

      desc "delete JOB", "Delete the job"
      def delete(job)
        @client = Helper.setup(parent_options)
        puts @client.job.delete(job)
      end

      desc "restrict JOB", "Restricts a job to a specific node"
      method_option :node, :aliases => "-n", :desc => "Node to be restricted to"
      def restrict(job)
        @client = Helper.setup(parent_options)
        if options[:node]
          @client.job.restrict_to_node(job, options[:node])
        else
          say "You need to specify the node to be restricted to.", :red
        end
      end

    end
  end
end
