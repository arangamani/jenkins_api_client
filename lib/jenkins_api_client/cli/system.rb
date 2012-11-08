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
  module CLI
    class System < Thor
      include Thor::Actions

      desc "quietdown", "Puts the Jenkins server in Quiet down mode"
      def quietdown
        @client = Helper.setup(parent_options)
        @client.system.quiet_down
      end

      desc "cancel_quietdown", "Cancels the Quiet down mode of Jenkins server"
      def cancel_quietdown
        @client = Helper.setup(parent_options)
        @client.system.cancel_quiet_down
      end

      desc "restart", "Restarts the Jenkins server"
      method_option :safe, :aliases => "-s", :desc => "Safe restart"
      def restart
        @client = Helper.setup(parent_options)
        if options[:safe]
          @client.system.restart(true)
        else
          @client.system.restart
        end
      end

    end
  end
end
