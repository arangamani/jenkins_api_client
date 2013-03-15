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
    # This class provides various command line operations to System class.
    class System < Thor
      include Thor::Actions

      desc "quietdown", "Puts the Jenkins server in Quiet down mode"
      # CLI command that puts Jenkins in Quiet Down mode
      def quietdown
        @client = Helper.setup(parent_options)
        @client.system.quiet_down
      end

      desc "cancel_quietdown", "Cancels the Quiet down mode of Jenkins server"
      # CLI command that cancels Jenkins from Quiet Down mode
      def cancel_quietdown
        @client = Helper.setup(parent_options)
        @client.system.cancel_quiet_down
      end

      desc "reload", "Reload Jenkins server"
      # CLI command to reload Jenkins configuration from disk
      def reload
        @client = Helper.setup(parent_options)
        @client.system.reload
      end

      desc "restart", "Restarts the Jenkins server"
      method_option :force, :type => :boolean, :aliases => "-s",
        :desc => "Force restart"
      # CLI command to (force) restart Jenkins
      def restart
        @client = Helper.setup(parent_options)
        force = options[:force] ? true : false
        @client.system.restart(force)
      end

    end
  end
end
