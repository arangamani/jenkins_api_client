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

require 'jenkins_api_client/urihelper'

module JenkinsApi
  class Client
    # This class communicates with Jenkins "/computer" API to obtain details
    # about nodes or slaves connected to the Jenkins.
    #
    class Node
      include JenkinsApi::UriHelper

      # General attributes of a node.
      # This allows the following methods to be called on this node object.
      # These methods are defined using define_method and are prefixed
      # with get_.
      #
      #   def get_busyExecutors
      #   def get_displayName
      #   def get_totalExecutors
      #
      GENERAL_ATTRIBUTES = [
        "busyExecutors",
        "displayName",
        "totalExecutors"
      ].freeze

      # Properties of a node.
      # The following methods are defined to be called on the node object
      # and are prefixed with is_ and end with ? as they return true or false.
      #
      #   def is_idle?(node_name)
      #   def is_jnlpAgent?(node_name)
      #   def is_launchSupported?(node_name)
      #   def is_manualLaunchAllowed?(node_name)
      #   def is_offline?(node_name)
      #   def is_temporarilyOffline?(node_name)
      #
      NODE_PROPERTIES = [
        "idle",
        "jnlpAgent",
        "launchSupported",
        "manualLaunchAllowed",
        "offline",
        "temporarilyOffline"
      ].freeze

      # Node specific attributes.
      # The following methods are defined using define_method.
      # These methods are prefixed with get_node_.
      #
      #   def get_node_numExecutors(node_name)
      #   def get_node_icon(node_name)
      #   def get_node_displayName(node_name)
      #   def get_node_loadStatistics(node_name)
      #   def get_node_monitorData(node_name)
      #   def get_node_offlineCause(node_name)
      #   def get_node_oneOffExecutors(node_name)
      #
      NODE_ATTRIBUTES = [
        "numExecutors",
        "icon",
        "displayName",
        "loadStatistics",
        "monitorData",
        "offlineCause",
        "oneOffExecutors"
      ].freeze

      # Initializes a new node object
      #
      # @param client [Client] the client object
      #
      # @return [Node] the node object
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
      end

      # Gives the string representation of the Object
      #
      def to_s
        "#<JenkinsApi::Client::Node>"
      end

      # Creates a new node with the specified parameters
      #
      # @param [Hash] params parameters for creating a dumb slave
      #  * +:name+ name of the slave
      #  * +:description+ description of the new slave
      #  * +:executors+ number of executors
      #  * +:remote_fs+ Remote FS root
      #  * +:labels+ comma separated list of labels
      #  * +:mode+ mode of the slave: normal, exclusive
      #  * +:slave_host+ Hostname/IP of the slave
      #  * +:slave_port+ Slave port
      #  * +:private_key_file+ Private key file of master
      #  * +:credentials_id+ Id for credential in Jenkins
      #
      # @example Create a Dumb Slave
      #   create_dumb_slave(
      #     :name => "slave1",
      #     :slave_host => "10.10.10.10",
      #     :private_key_file => "/root/.ssh/id_rsa",
      #     :executors => 10,
      #     :labels => "slave, ruby"
      #   )
      #
      def create_dumb_slave(params)
        unless params[:name] && params[:slave_host] && params[:private_key_file]
          raise ArgumentError, "Name, slave host, and private key file are" +
            " required for creating a slave."
        end

        @logger.info "Creating a dumb slave '#{params[:name]}'"
        @logger.debug "Creating a dumb slave with params: #{params.inspect}"
        default_params = {
          :description => "Automatically created through jenkins_api_client",
          :executors => 2,
          :remote_fs => "/var/jenkins",
          :labels => params[:name],
          :slave_port => 22,
          :mode => "normal",
          :private_key_file => "",
          :credentials_id => ""
        }

        params = default_params.merge(params)
        labels = params[:labels].split(/\s*,\s*/).join(" ")
        mode = params[:mode].upcase

        post_params = {
          "name" => params[:name],
          "type" => "hudson.slaves.DumbSlave$DescriptorImpl",
          "json" => {
            "name" => params[:name],
            "nodeDescription" => params[:description],
            "numExecutors" => params[:executors],
            "remoteFS" => params[:remote_fs],
            "labelString" => labels,
            "mode" => mode,
            "type" => "hudson.slaves.DumbSlave$DescriptorImpl",
            "retentionStrategy" => {
              "stapler-class" => "hudson.slaves.RetentionStrategy$Always"
            },
            "nodeProperties" => {
              "stapler-class-bag" => "true"
            },
            "launcher" => {
              "stapler-class" => "hudson.plugins.sshslaves.SSHLauncher",
              "host" => params[:slave_host],
              "port" => params[:slave_port],
              "username" => params[:slave_user],
              "privatekey" => params[:private_key_file],
              "credentialsId" => params[:credentials_id]
            }
          }.to_json
        }
        @logger.debug "Modified params posted to create slave:" +
          " #{post_params.inspect}"
        @client.api_post_request("/computer/doCreateItem", post_params)
      end

      def create_dump_slave(params)
        @logger.warn '[DEPRECATED] Please use create_dumb_slave instead.'
        create_dumb_slave(params)
      end

      # Deletes the specified node
      #
      # @param [String] node_name Name of the node to delete
      #
      def delete(node_name)
        @logger.info "Deleting node '#{node_name}'"
        if list.include?(node_name)
          @client.api_post_request("/computer/#{path_encode node_name}/doDelete")
        else
          raise "The specified node '#{node_name}' doesn't exist in Jenkins."
        end
      end

      # Deletes all slaves from Jenkins. The master will be the only node alive
      # after the exection of this call.
      #
      # @note This method will remove all slaves from Jenkins. Please use with
      #       caution.
      #
      def delete_all!
        @logger.info "Deleting all nodes (except master) from jenkins"
        list.each { |node| delete(node) unless node == "master" }
      end

      # This method returns two lists 1) nodes online 2) nodes offline
      #
      # @param [String] filter a regex to filter node names
      # @param [Bool] ignorecase whether to be case sensitive or not
      #
      def online_offline_lists(filter = nil, ignorecase = true)
        @logger.info "Obtaining nodes from jenkins matching filter '#{filter}'"
        offline_node_names = []
        online_node_names = []
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each do |computer|
            if computer["displayName"] =~ /#{filter}/i
              if computer["offline"] == true
                offline_node_names << computer["displayName"]
              else
                online_node_names << computer["displayName"]
              end
            end
        end
        return online_node_names, offline_node_names
      end

      # This method lists all nodes
      #
      # @param [String] filter a regex to filter node names
      # @param [Bool] ignorecase whether to be case sensitive or not
      #
      def list(filter = nil, ignorecase = true, slaveonly = false)
        @logger.info "Obtaining nodes from jenkins matching filter '#{filter}'"
        node_names = []
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each do |computer|
            if computer["displayName"] =~ /#{filter}/i
              unless slaveonly && computer["displayName"] == "master"
                node_names << computer["displayName"]
              end
            end
        end
        node_names
      end

      # Identifies the index of a node name in the array node nodes
      #
      # @param [String] node_name name of the node
      #
      def index(node_name)
        response_json = @client.api_get_request("/computer")
        response_json["computer"].each_with_index do |computer, index|
          return index if computer["displayName"] == node_name
        end
      end

      # Defines methods for general node attributes.
      #
      GENERAL_ATTRIBUTES.each do |meth_suffix|
        define_method("get_#{meth_suffix}") do
          @logger.info "Obtaining '#{meth_suffix}' attribute from jenkins"
          response_json = @client.api_get_request("/computer", "tree=#{path_encode meth_suffix}[*[*[*]]]")
          response_json["#{meth_suffix}"]
        end
      end

      # Defines methods for node properties.
      #
      NODE_PROPERTIES.each do |meth_suffix|
        define_method("is_#{meth_suffix}?") do |node_name|
          @logger.info "Obtaining '#{meth_suffix}' property of '#{node_name}'"
          node_name = "(master)" if node_name == "master"
          response_json = @client.api_get_request("/computer/#{path_encode node_name}", "tree=#{path_encode meth_suffix}")
          resp = response_json["#{meth_suffix}"].to_s
          resp =~ /False/i ? false : true
        end
      end

      # Defines methods for node specific attributes.
      NODE_ATTRIBUTES.each do |meth_suffix|
        define_method("get_node_#{meth_suffix}") do |node_name|
          @logger.info "Obtaining '#{meth_suffix}' attribute of '#{node_name}'"
          node_name = "(master)" if node_name == "master"
          response_json = @client.api_get_request("/computer/#{path_encode node_name}", "tree=#{path_encode meth_suffix}[*[*[*]]]")
          response_json["#{meth_suffix}"]
        end
      end

      # Changes the mode of a slave node in Jenkins
      #
      # @param [String] node_name name of the node to change mode for
      # @param [String] mode mode to change to
      #
      def change_mode(node_name, mode)
        @logger.info "Changing the mode of '#{node_name}' to '#{mode}'"
        mode = mode.upcase
        xml = get_config(node_name)
        n_xml = Nokogiri::XML(xml)
        desc = n_xml.xpath("//mode").first
        desc.content = "#{mode.upcase}"
        xml_modified = n_xml.to_xml
        post_config(node_name, xml_modified)
      end

      # Obtains the configuration of node from Jenkins server
      #
      # @param [String] node_name name of the node
      #
      def get_config(node_name)
        @logger.info "Obtaining the config.xml of node '#{node_name}'"
        node_name = "(master)" if node_name == "master"
        @client.get_config("/computer/#{path_encode node_name}")
      end

      # Posts the given config.xml to the Jenkins node
      #
      # @param [String] node_name name of the node
      # @param [String] xml Config.xml of the node
      #
      def post_config(node_name, xml)
        @logger.info "Posting the config.xml of node '#{node_name}'"
        node_name = "(master)" if node_name == "master"
        @client.post_config("/computer/#{path_encode node_name}/config.xml", xml)
      end

      # Toggles the temporarily offline state of the Jenkins node
      #
      # @param [String] node_name name of the node
      # @param [String] reason Offline reason why the node is offline
      #
      def toggle_temporarilyOffline(node_name, reason="")
        @logger.info "Toggling the temporarily offline status of of node '#{node_name}' with reason '#{reason}'"
        node_name = "(master)" if node_name == "master"
        previous_state = is_temporarilyOffline?(node_name)
        @client.api_post_request("/computer/#{path_encode node_name}/toggleOffline?offlineMessage=#{path_encode reason}")
        new_state = is_temporarilyOffline?(node_name)
        if new_state == previous_state
          raise "The specified node '#{node_name}' was unable to change offline state."
        end
        new_state
      end
    end
  end
end
