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

require 'jenkins_api_client/urihelper'

module JenkinsApi
  class Client
    # This class communicates with Jenkins API at the root address to obtain details
    # on the page displayed to users on the Jenkins' 'homepage,' and other
    # data items such as quietingDown
    class Root
      include JenkinsApi::UriHelper

      # Initializes a new root object
      #
      # @param client [Client] the client object
      #
      # @return [Root] the root object
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
      end

      # Return a string representation of the object
      #
      def to_s
        "#<JenkinsApi::Client::Root>"
      end

      # Check if Jenkins is in shutdown mode
      #
      # @return [Boolean] true if server in shutdown mode
      #
      def quieting_down?
        response_json = @client.api_get_request('', 'tree=quietingDown')
        response_json['quietingDown']
      end

      # Get message displayed to users on the homepage
      #
      # @return [String] description - message displayed to users
      #
      def description
        response_json = @client.api_get_request('', 'tree=description')
        response_json['description']
      end
    end
  end
end
