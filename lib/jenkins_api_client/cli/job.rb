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

module JenkinsApi
  module CLI
    # This class provides various command line operations related to jobs.
    class Job < Thor
      include Thor::Actions

      desc "list", "List jobs"
      method_option :status, :aliases => "-t", :desc => "Status to filter"
      method_option :filter, :aliases => "-f",
        :desc => "Regular expression to filter jobs"
      # CLI command to list all jobs in Jenkins or the ones matched by status
      # or a regular expression
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
      # CLI command to recreate a job on Jenkins
      def recreate(job)
        @client = Helper.setup(parent_options)
        @client.job.recreate(job)
      end

      desc "build JOB", "Build a job"
      # CLI command to build a job given the name of the job
      #
      # @param [String] job Name of the job
      #
      option :params, :type => :hash, :default => {}
      option :opts, :type => :hash, :default => {}
      def build(job)
        @client = Helper.setup(parent_options)
        @client.job.build(job, options[:params], options[:opts])
      end

      desc "status JOB", "Get the current build status of a job"
      # CLI command to get the status of a job
      #
      # @param [String] job Name of the job
      #
      def status(job)
        @client = Helper.setup(parent_options)
        puts @client.job.get_current_build_status(job)
      end

      desc "delete JOB", "Delete the job"
      # CLI command to delete a job
      #
      # @param [String] job Name of the job
      #
      def delete(job)
        @client = Helper.setup(parent_options)
        puts @client.job.delete(job)
      end

      desc "console JOB", "Print the progressive console output of a job"
      method_option :sleep, :aliases => "-z",
        :desc => "Time to wait between querying the API for console output"
      # CLI command to obtain console output for a job. Make sure the log
      # location is set to something other than STDOUT. By default it is set to
      # STDOUT. If the log messages are printed on the same console, the
      # console output will get garbled.
      #
      # @param [String] job Name of the job
      #
      def console(job)
        @client = Helper.setup(parent_options)
        # Print progressive console output
        response = @client.job.get_console_output(job)
        puts response['output'] unless response['more']
        while response['more']
          size = response['size']
          puts response['output'] unless response['output'].chomp.empty?
          sleep options[:sleep].to_i if options[:sleep]
          response = @client.job.get_console_output(job, 0, size)
        end
        # Print the last few lines
        puts response['output'] unless response['output'].chomp.empty?
      end

      desc "restrict JOB", "Restricts a job to a specific node"
      method_option :node, :aliases => "-n", :desc => "Node to be restricted to"
      # CLI command to restrict a job to a node
      #
      # @param [String] job Name of the job
      #
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
