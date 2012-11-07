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

require 'timeout'

module JenkinsApi
  class Client
    class System

      def initialize(client)
        @client = client
      end

      def to_s
        "#<JenkinsApi::Client::System>"
      end

      def quiet_down
        @client.api_post_request("/quietDown")
      end

      def cancel_quiet_down
        @client.api_post_request("/cancelQuietDown")
      end

      def restart(safe = false)
        if safe
          @client.api_post_request("/safeRestart")
        else
          @client.api_post_request("/restart")
        end
      end

      def wait_for_ready
        Timeout::timeout(120) do
          while true do
            response = @client.get_root
            puts "Waiting for jenkins to restart: "
            if (response.body =~ /Please wait while Jenkins is restarting/ || response.body =~ /Please wait while Jenkins is getting ready to work/)
              sleep 5
              redo
            else
               break
            end
          end
        end
      end

    end
  end
end
