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
    class BuildQueue

      # Initializes a new BuildQueue object.
      #
      # @param [Object] client a reference to Client
      #
      def initialize(client)
        @client = client
      end

      # Returns a string representation of BuildQueue class.
      #
      def to_s
        "#<JenkinsApi::Client::BuildQueue>"
      end

      # Gives the number of jobs currently in the build queue
      #
      def size
        response_json = @client.api_get_request("/queue")
        response_json["items"].size
      end

      # Lists all tasks currently in the build queue
      #
      def list
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
      # @return [FixNum] age in seconds
      #
      def get_age(task_name)
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
        response_json = @client.api_get_request("/queue")
        details = {}
        response_json["items"].each do |item|
          details = item if item["task"]["name"]
        end
        details
      end

      # Obtains the causes from the build queue for the specified task
      #
      # @param [String] task_name
      #
      # @return [Array] causes for the task to be in queue
      #
      def get_causes(task_name)
        causes = nil
        details = get_details(task_name)
        unless details.empty?
          causes = details["actions"]["causes"]
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
        reason = nil
        details = get_details(task_name)
        unless details.empty?
          reason = details["why"]
        end
        reason
      end

      # Obtains the ETA given by Jenkins if any
      #
      # @param[String] task_name name of the task
      #
      # @return [String] ETA for the task, nil if no task found or ETA is
      #                  not available
      #
      def get_eta(task_name)
        eta = nil
        details = get_details(task_name)
        unless details.empty?
          matched = details["why"].match(/.*\(ETA:(.*)\)/)
          eta = matched[1].strip unless matched.nil?
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
      # @return [TrueClass|FalseClass] buildable or not
      #
      def is_buildable?(task_name)
        buildable = nil
        details = get_details(task_name)
        unless details.empty?
          buildable = details["buildable"] == "true" ? true : false
        end
        buildable
      end

      # Obtains whether the task is blocked
      #
      # @param [String] task_name name of the task
      #
      # @return [TrueClass|FalseClass] blocked or not
      #
      def is_blocked?(task_name)
        blocked = nil
        details = get_details(task_name)
        unless details.empty?
          blocked = details["blocked"] == "true" ? true : false
        end
        blocked
      end

      # Obtains whether the task is stuck
      #
      # @param [String] task_name name of the task
      #
      # @return [TrueClass|FalseClass] stuck or not
      #
      def is_stuck?(task_name)
        stuck = nil
        details = get_details(task_name)
        unless details.empty?
          stuck = details["stuck"] == "true" ? true : false
        end
        stuck
      end

    end
  end
end
