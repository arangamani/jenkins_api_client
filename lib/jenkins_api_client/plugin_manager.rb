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
    # This classes communicates with the /pluginManager API for listing
    # installed plugins, installing new plgins through hacks, and performing a
    # lot of operations on installed plugins. It also gives the ability to
    # obtain the details about available plugins in Jenkins update center by
    # commmunicating with /updateCenter API.
    #
    class PluginManager

      # Initializes a new PluginManager object.
      #
      # @param [Object] client a reference to Client
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
      end

      # Returns a string representation of BuildQueue class.
      #
      def to_s
        "#<JenkinsApi::Client::PluginManager>"
      end

      # Obtains the list of installed plugins from Jenkins along with their
      # version numbers.
      #
      # @return [Hash<String, String>] installed plugins and their versions.
      #   returns an empty hash if there are no plugins installed in jenkins.
      #
      # @example Listing installed plugins from jenkins
      #   >> @client.plugin.list_installed
      #   => [
      #        {"shortName"=>"mailer", "version"=>"1.5"},
      #        {"shortName"=>"external-monitor-job", "version"=>"1.1"},
      #        {"shortName"=>"ldap", "version"=>"1.2"}
      #      ]
      #
      def list_installed
        response = @client.api_get_request(
          "/pluginManager",
          "tree=plugins[shortName,version]"
        )
        response.empty? ? response : response["plugins"]
      end

      # List the available plugins from jenkins update center along with their
      # version numbers
      #
      # @return [Hash<String, String>] available plugins and their versions.
      #   returns an empty if no plugins are available.
      #
      # @example Listing available plugins from jenkins
      #   >> @client.plugin.list_available
      #   => [
      #        {"name"=>"accurev", "version"=>"0.6.18"},
      #        {"name"=>"active-directory", "version"=>"1.33"},
      #        {"name"=>"AdaptivePlugin", "version"=>"0.1"},
      #        ...
      #        {"name"=>"zubhium", "version"=>"0.1.6"}
      #      ]
      #
      def list_available
        response = @client.api_get_request(
          "/updateCenter/coreSource",
          "tree=availables[name,version]"
        )
        response.empty? ? response : response["availables"]
      end

      # Installs a specific plugin or list of plugins. This method will install
      # the latest available plugins that jenkins reports. The installation
      # might not take place right away for some plugins and they might require
      # restart of jenkins instances.
      #
      # @see Client.api_post_request
      # @see .restart_required?
      # @see System.restart
      #
      # @param plugins [String, Array] a single plugin or a list of plugins to
      #   be installed
      #
      # @return [String] the HTTP code from the plugin install POST request
      #
      # @example Installing a plugin and restart jenkins if required
      #   >> @client.plugin.install "s3"
      #   => "302" # Response code from plugin installation POST
      #   >> @client.plugin.restart_required?
      #   => true # A restart is required for the installation completion
      #   >> @client.system.restart(true)
      #   => "302" # A force restart is performed
      #
      def install(plugins)
        # Convert the input argument to an array if it is not already an array
        plugins = [plugins] unless plugins.is_a?(Array)

        # Build the form data to post to jenkins
        form_data = {}
        plugins.each { |plugin| form_data["plugin.#{plugin}.default"] = "on" }
        @client.api_post_request("/pluginManager/install", form_data)
      end

      # Whether restart required for the completion of plugin installations
      #
      # @see Client.api_get_request
      #
      # @return [Boolean] whether restart is required for the completion for
      #   plugin installations.
      #
      def restart_required?
        response = @client.api_get_request(
          "/updateCenter",
          "tree=restartRequiredForCompletion"
        )
        response["restartRequiredForCompletion"]
      end
    end
  end
end
