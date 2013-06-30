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

      # Returns a string representation of PluginManager class.
      #
      def to_s
        "#<JenkinsApi::Client::PluginManager>"
      end

      # Obtains the list of installed plugins from Jenkins along with their
      # version numbers.
      #
      # @param skip_bundled [Boolean] whether to skip the bundled plugins (came
      #   with jenkins installation)
      #
      # @return [Hash<String, String>] installed plugins and their versions.
      #   returns an empty hash if there are no plugins installed in jenkins.
      #
      # @example Listing installed plugins from jenkins
      #   >> @client.plugin.list_installed
      #   => {
      #        "mailer" => "1.5",
      #        "external-monitor-job" => "1.1",
      #        "ldap" => "1.2"
      #      }
      #   >> @client.plugin.list_installed(true)
      #   => {}
      #
      def list_installed(skip_bundled = false)
        plugins = @client.api_get_request(
          "/pluginManager",
          "tree=plugins[shortName,version]"
        )["plugins"]
        installed =
          Hash[plugins.map { |plugin| [plugin["shortName"], plugin["version"]] }]
        if skip_bundled
          bundled = list_by_criteria("bundled")
          bundled.keys.each { |plugin| installed.delete(plugin) }
        end
        installed
      end

      # Lists the installed plugins in Jenkins based on the provided criteria.
      #
      # @param criteria [String] the criteria to be filtered on. Available
      #   criteria: "active", "bundled", "deleted", "downgradable", "enabled",
      #   "hasUpdate", "pinned". The criteria are self explanatory.
      #
      # @return [Hash<String, String>] bundled plugins and their versions.
      #   returns an empty hash if there are no bundled plugins in jenkins.
      #
      # @example Listing bundled plugins from jenkins
      #   >> @client.plugin.list_by_criteria("downgradable")
      #   => {
      #        "mailer" => "1.5",
      #        "external-monitor-job" => "1.1",
      #        "ldap" => "1.2"
      #      }
      #
      def list_by_criteria(criteria)
        supported_criteria = [
          "active", "bundled", "deleted", "downgradable", "enabled",
          "hasUpdate", "pinned"
        ].freeze
        unless supported_criteria.include?(criteria)
          raise ArgumentError, "Criteria '#{criteria}' is not supported." +
            " Supported criteria: #{supported_criteria.inspect}"
        end
        plugins = @client.api_get_request(
          "/pluginManager",
          "tree=plugins[shortName,version,#{criteria}]"
        )["plugins"]
        Hash[plugins.map do |plugin|
          [plugin["shortName"], plugin["version"]] if plugin[criteria]
        end]
      end

      # List the available plugins from jenkins update center along with their
      # version numbers
      #
      # @return [Hash<String, String>] available plugins and their versions.
      #   returns an empty if no plugins are available.
      #
      # @example Listing available plugins from jenkins
      #   >> @client.plugin.list_available
      #   => {
      #        "accurev" => "0.6.18",
      #        "active-directory" => "1.33",
      #        "AdaptivePlugin" => "0.1",
      #        ...
      #        "zubhium" => "0.1.6"
      #      }
      #
      def list_available
        availables = @client.api_get_request(
          "/updateCenter/coreSource",
          "tree=availables[name,version]"
        )["availables"]
        Hash[availables.map { |plugin| [plugin["name"], plugin["version"]] }]
      end

      # List the available updates for plugins from jenkins update center
      # along with their version numbers
      #
      # @return [Hash<String, String>] available plugin updates and their
      #   versions. returns an empty if no plugins are available.
      #
      # @example Listing available plugin updates from jenkins
      #   >> @client.plugin.list_updates
      #   => {
      #        "ldap" => "1.5",
      #        "ssh-slaves" => "0.27",
      #        "subversion" => "1".50
      #      }
      #
      def list_updates
        updates = @client.api_get_request(
          "/updateCenter/coreSource",
          "tree=updates[name,version]"
        )["updates"]
        Hash[updates.map { |plugin| [plugin["name"], plugin["version"]] }]
      end

      # Installs a specific plugin or list of plugins. This method will install
      # the latest available plugins that jenkins reports. The installation
      # might not take place right away for some plugins and they might require
      # restart of jenkins instances. This method makes a single POST request
      # for the installation of multiple plugins. Updating plugins can be done
      # the same way. When the install action is issued, it gets the latest
      # version of the plugin if the plugin is outdated.
      #
      # @see Client.api_post_request
      # @see .restart_required?
      # @see System.restart
      # @see .uninstall
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
        @logger.info "Installing plugins: #{plugins.inspect}"

        # Build the form data to post to jenkins
        form_data = {}
        plugins.each { |plugin| form_data["plugin.#{plugin}.default"] = "on" }
        @client.api_post_request("/pluginManager/install", form_data)
      end
      alias_method :update, :install

      # Uninstalls the specified plugin or list of plugins. Only the user
      # installed plugins can be uninstalled. The plugins installed by default
      # by jenkins (also known as bundled plugins) cannot be uninstalled. The
      # call will succeed but the plugins wil still remain in jenkins installed.
      # This method makes a POST request for every plugin requested - so it
      # might lead to some delay if a big list is provided.
      #
      # @see Client.api_post_request
      # @see .restart_required?
      # @see System.restart
      # @see .install
      #
      # @param plugins [String, Array] a single plugin or list of plugins to be
      #   uninstalled
      #
      def uninstall(plugins)
        plugins = [plugins] unless plugins.is_a?(Array)
        @logger.info "Uninstalling plugins: #{plugins.inspect}"
        plugins.each do |plugin|
          @client.api_post_request(
            "/pluginManager/plugin/#{plugin}/doUninstall"
          )
        end
      end

      # @todo Write description
      #
      # @see Client.api_post_request
      # @see .restart_required?
      # @see System.restart
      # @see .disable
      #
      # @param plugins [String, Array] a single plugin or list of plugins to be
      #   uninstalled
      #
      def enable(plugins)
        plugins = [plugins] unless plugins.is_a?(Array)
        @logger.info "Uninstalling plugins: #{plugins.inspect}"
        plugins.each do |plugin|
          @client.api_post_request(
            "/pluginManager/plugin/#{plugin}/makeEnabled"
          )
        end
      end

      # @todo Write description
      #
      # @see Client.api_post_request
      # @see .restart_required?
      # @see System.restart
      # @see .enable
      #
      # @param plugins [String, Array] a single plugin or list of plugins to be
      #   uninstalled
      #
      def disable(plugins)
        plugins = [plugins] unless plugins.is_a?(Array)
        @logger.info "Uninstalling plugins: #{plugins.inspect}"
        plugins.each do |plugin|
          @client.api_post_request(
            "/pluginManager/plugin/#{plugin}/makeDisabled"
          )
        end
      end

      # Whether restart required for the completion of plugin
      # installations/uninstallations
      #
      # @see Client.api_get_request
      #
      # @return [Boolean] whether restart is required for the completion for
      #   plugin installations/uninstallations.
      #
      def restart_required?
        response = @client.api_get_request(
          "/updateCenter",
          "tree=restartRequiredForCompletion"
        )
        response["restartRequiredForCompletion"] ||
          !list_by_criteria("deleted").empty?
      end
    end
  end
end
