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

module JenkinsApi
  class Client
    # This classes communicates with the Build Queue API exposed by Jenkins at
    # "/queue" that gives information about jobs/tasks in the queue and their
    # details.
    #
    class BuildQueue

      # Initializes a new BuildQueue object.
      #
      # @param client [Client] the client object
      #
      # @return [BuildQueue] the build queue object
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
      end

      # Returns a string representation of BuildQueue class.
      #
      def to_s
        "#<JenkinsApi::Client::BuildQueue>"
      end

      # Gives the number of jobs currently in the build queue
      #
      def size
        @logger.info "Obtaining the number of tasks in build queue"
        response_json = @client.api_get_request("/queue")
        response_json["items"].size
      end

      # Lists all tasks currently in the build queue
      #
      def list
        @logger.info "Obtaining the tasks currently in the build queue"
        response_json = @client.api_get_request("/queue")
        tasks = []
        response_json["items"].each do |item|
          tasks << item["task"]["name"]
        end
        tasks
      end

      # Gets the time number of seconds the task is in the queue
      #
      # @param [String] task_name Name of the task/job
      #
      # @return [Fixnum] age in seconds
      #
      def get_age(task_name)
        @logger.info "Obtaining the age of task '#{task_name}' from the" +
          " build queue"
        age = nil
        details = get_details(task_name)
        unless details.empty?
          age = Time.now - Time.at(details["inQueueSince"].to_i/1000)
        end
        age
      end

      # Obtains the detail Hash from the API response
      #
      # @param [String] task_name Name of the task/job
      #
      # @return [Hash] Queue details of the specified task/job
      #
      def get_details(task_name)
        @logger.info "Obtaining the details of task '#{task_name}' from the" +
          " build queue"
        response_json = @client.api_get_request("/queue")
        details = {}
        response_json["items"].each do |item|
          details = item if item["task"]["name"] == task_name
        end
        details
      end

      # Obtain the item in the queue provided the ID of the task
      #
      # @param task_id [String] the ID of the task
      #
      # @return [Hash] the details of the item in the queue
      #
      def get_item_by_id(task_id)
        @logger.info "Obtaining the details of task with ID '#{task_id}'"
        @client.api_get_request("/queue/item/#{task_id}")
      end

      # Obtains the causes from the build queue for the specified task
      #
      # @param [String] task_name
      #
      # @return [Array] causes for the task to be in queue
      #
      def get_causes(task_name)
        @logger.info "Obtaining the causes of task '#{task_name}' from the" +
          " build queue"
        causes = nil
        details = get_details(task_name)
        unless details.empty?
          causes = []
          details["actions"].each do |action|
            causes << action["causes"]
          end
        end
        causes
      end

      # Obtains the reason why the task is in queue
      #
      # @param [String] task_name name of the task
      #
      # @return [String] reason for being in queue, nil if no task found
      #
      def get_reason(task_name)
        @logger.info "Obtaining the reason of task '#{task_name}' from the" +
          " build queue"
        reason = nil
        details = get_details(task_name)
        unless details.empty?
          reason = details["why"]
        end
        reason
      end

      # Obtains the ETA given by Jenkins if any
      #
      # @param [String] task_name name of the task
      #
      # @return [String] ETA for the task, nil if no task found and N/A for
      #                  tasks with no ETA info.
      #
      def get_eta(task_name)
        @logger.info "Obtaining the ETA for the task '#{task_name}' from the" +
          " build queue"
        eta = nil
        details = get_details(task_name)
        unless details.empty?
          matched = details["why"].match(/.*\(ETA:(.*)\)/)
          if matched.nil?
            # Task is found, but ETA information is not available
            eta = "N/A"
          else
            # ETA information is available
            eta = matched[1].strip
          end
        end
        eta
      end

      # Obtains the ID of the task from the queue
      #
      # @param [String] task_name name of the task
      #
      # @return [String] ID of the task, nil of no task is found
      #
      def get_id(task_name)
        @logger.info "Obtaining the ID of task '#{task_name}' from the" +
          " build queue"
        id = nil
        details = get_details(task_name)
        unless details.empty?
          id = details["id"]
        end
        id
      end

      # Obtains the params from the build queue
      #
      # @param [String] task_name name of the task
      #
      # @return [String] params, nil if the no task is found
      #
      def get_params(task_name)
        @logger.info "Obtaining the build parameters of task '#{task_name}'" +
          " from the build queue"
        params = nil
        details = get_details(task_name)
        unless details.empty?
          params = details["params"]
        end
        params
      end

      # Obtains whether the task is buildable
      #
      # @param [String] task_name name of the task
      #
      # @return [Boolean] buildable or not
      #
      def is_buildable?(task_name)
        @logger.info "Checking if task '#{task_name}' from the build queue" +
          " is buildable"
        buildable = nil
        details = get_details(task_name)
        unless details.empty?
          buildable = details["buildable"]
        end
        buildable
      end

      # Obtains whether the task is blocked
      #
      # @param [String] task_name name of the task
      #
      # @return [Boolean] blocked or not
      #
      def is_blocked?(task_name)
        @logger.info "Checking if task '#{task_name}' from the build queue" +
          " is blocked"
        blocked = nil
        details = get_details(task_name)
        unless details.empty?
          blocked = details["blocked"]
        end
        blocked
      end

      # Obtains whether the task is stuck
      #
      # @param [String] task_name name of the task
      #
      # @return [Boolean] stuck or not
      #
      def is_stuck?(task_name)
        @logger.info "Checking if task '#{task_name}' from the build queue" +
          " is stuck"
        stuck = nil
        details = get_details(task_name)
        unless details.empty?
          stuck = details["stuck"]
        end
        stuck
      end

    end
  end
end
