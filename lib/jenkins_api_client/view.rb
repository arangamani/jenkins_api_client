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
    class View

      # Initializes a new view object
      #
      # @param [Object] client reference to Client
      #
      def initialize(client)
        @client = client
      end

      def to_s
        "#<JenkinsApi::Client::View>"
      end

      # This method lists all views
      #
      # @param [String] filter a regex to filter view names
      # @param [Bool] ignorecase whether to be case sensitive or not
      #
      def list(filter = nil, ignorecase = true)
        view_names = []
        response_json = @client.api_get_request("/")
        response_json["views"].each { |view|
          view_names << view["name"] if view["name"] =~ /#{filter}/i
        }
        view_names
      end

      # Add a job to view
      #
      # @param [String] view_name
      # @param [String] job_name
      #
      def add_job(view_name, job_name)
        @client.api_post_request("/view/#{view_name}/addJobToView?name=#{job_name}")
      end

      # Remove a job from view
      #
      # @param [String] view_name
      # @param [String] job_name
      #
      def remove_job(view_name, job_name)
        @client.api_post_request("/view/#{view_name}/removeJobFromView?name=#{job_name}")
      end

    end
  end
end
