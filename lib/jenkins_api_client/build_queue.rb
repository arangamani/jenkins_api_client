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
      def size
        response_json = @client.api_get_request("/queue")
        response_json["items"].size
      end

      # Lists all tasks currently in the build queue
      #
      def list_tasks
        response_json = @client.api_get_request("/queue")
        tasks = []
        response_json["items"].each do |item|
          tasks << item["task"]["name"]
        end
        tasks
      end

      def get_age(task_name)
        age = nil
        details = get_details(task_name)
        unless details.empty?
          age = Time.now - Time.at(details["inQueueSince"].to_i/1000)
        end
        age
      end

      def get_details(task_name)
        response_json = @client.api_get_request("/queue")
        details = {}
        response_json["items"].each do |item|
          details = item if item["task"]["name"]
        end
        details
      end

    end
  end
end
