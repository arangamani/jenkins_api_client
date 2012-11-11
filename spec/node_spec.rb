#
# Specifying JenkinsApi::Client::Node class capabilities
# Author Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::Node do
  context "With properly initialized client" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/login.yml'
      @node_name = 'master'
      begin
        @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    it "Should be able to list all nodes" do
      @client.node.list.class.should == Array
    end

    it "Should be able to list all general attributes" do
      node_attributes = JenkinsApi::Client::Node::GENERAL_ATTRIBUTES
      node_attributes.each do |attr|
        @client.node.method("get_#{attr}").call
      end
    end

    it "Should be able to list all node properties" do
      node_properties = JenkinsApi::Client::Node::NODE_PROPERTIES
      node_properties.each do |property|
        @client.node.method("is_#{property}?").call(@node_name)
      end
    end

    it "Should be able to list all node attributes" do
      node_attributes = JenkinsApi::Client::Node::NODE_ATTRIBUTES
      node_attributes.each do |attr|
        @client.node.method("get_node_#{attr}").call(@node_name)
      end
    end

  end
end
