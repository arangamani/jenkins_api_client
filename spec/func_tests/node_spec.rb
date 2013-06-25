#
# Specifying JenkinsApi::Client::Node class capabilities
# Author Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::Node do
  context "With properly initialized client" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/spec.yml'
      @valid_post_responses = [200, 201, 302]
      @node_name = 'master'
      begin
        @client = JenkinsApi::Client.new(
          YAML.load_file(File.expand_path(@creds_file, __FILE__))
        )
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end

      @client.node.create_dump_slave(
        :name => "slave",
        :slave_host => "10.0.0.1",
        :private_key_file => "/root/.ssh/id_rsa"
      ) unless @client.node.list.include?("slave")
    end

    describe "InstanceMethods" do

      describe "#initialize" do
        it "Initializes without any exception" do
          expect(
            lambda{ node = JenkinsApi::Client::Node.new(@client) }
          ).not_to raise_error
        end
        it "Raises an error if a reference of client is not passed" do
          expect(
            lambda{ node JenkinsApi::Client::Node.new() }
          ).to raise_error
        end
      end

      describe "#create_dump_slave" do

        def test_and_validate(params)
          name = params[:name]
          @valid_post_responses.should include(
            @client.node.create_dump_slave(params).to_i
          )
          @client.node.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.node.delete(params[:name]).to_i
          )
          @client.node.list(name).include?(name).should be_false
        end

        it "accepts required params and creates the slave on jenkins" do
          params = {
            :name => "func_test_slave",
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          }
          test_and_validate(params)
        end
        it "accepts spaces and other characters in node name" do
          params = {
            :name => "slave with spaces and {special characters}",
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          }
          test_and_validate(params)
        end
        it "fails if name is missing" do
          params = {
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          }
          expect(
            lambda{ @client.node.create_dump_slave(params) }
          ).to raise_error
        end
        it "fails if slave_host is missing" do
          params = {
            :name => "func_test_slave",
            :private_key_file => "/root/.ssh/id_rsa"
          }
          expect(
            lambda{ @client.node.create_dump_slave(params) }
          ).to raise_error
        end
        it "fails if private_key_file is missing" do
          params = {
            :name => "func_test_slave",
            :slave_host => "10.10.10.10"
          }
          expect(
            lambda{ @client.node.create_dump_slave(params) }
          ).to raise_error
        end
        it "fails if the slave already exists in Jenkins" do
          params = {
            :name => "func_test_slave",
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          }
          @valid_post_responses.should include(
            @client.node.create_dump_slave(params).to_i
          )
          expect(
            lambda{ @client.node.create_dump_slave(params) }
          ).to raise_error(JenkinsApi::Exceptions::NodeAlreadyExists)
          @valid_post_responses.should include(
            @client.node.delete(params[:name]).to_i
          )
        end
      end

      describe "#delete" do
        it "deletes the node given the name" do
          params = {
            :name => "func_test_slave",
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          }
          @valid_post_responses.should include(
            @client.node.create_dump_slave(params).to_i
          )
          @valid_post_responses.should include(
            @client.node.delete(params[:name]).to_i
          )
        end
        it "raises an error if the slave doesn't exist in Jenkins" do
          expect(
            lambda{ @client.node.delete("not_there") }
          ).to raise_error
        end
      end

      describe "#list" do
        it "Should be able to list all nodes" do
          @client.node.list.class.should == Array
        end
      end

      describe "GeneralAttributes" do
        general_attributes = JenkinsApi::Client::Node::GENERAL_ATTRIBUTES
        general_attributes.each do |attribute|
          describe "#get_#{attribute}" do
            it "should get the #{attribute} attribute" do
              @client.node.method("get_#{attribute}").call
            end
          end
        end
      end

      describe "NodeProperties" do
        node_properties = JenkinsApi::Client::Node::NODE_PROPERTIES
        node_properties.each do |property|
          describe "#is_#{property}" do
            it "should get the #{property} property" do
              @client.node.method("is_#{property}?").call(@node_name)
            end
          end
        end
      end

      describe "NodeAttributes" do
        node_attributes = JenkinsApi::Client::Node::NODE_ATTRIBUTES
        node_attributes.each do |attribute|
          describe "#get_node_#{attribute}" do
            it "Should be able to list all node attributes" do
              @client.node.method("get_node_#{attribute}").call(@node_name)
            end
          end
        end
      end

      describe "#change_mode" do
        it "changes the mode of the given slave to the given mode" do
          @valid_post_responses.should include(
            @client.node.change_mode("slave", "exclusive").to_i
          )
          @valid_post_responses.should include(
            @client.node.change_mode("slave", "normal").to_i
          )
        end
      end

      describe "#get_config" do
        it "obtaines the node config.xml from the server" do
          expect(
            lambda { @client.node.get_config("slave") }
          ).not_to raise_error
        end
      end

      describe "#post_config" do
        it "posts the given config.xml to the jenkins server's node" do
          expect(
            lambda {
              xml = @client.node.get_config("slave")
              @client.node.post_config("slave", xml)
            }
          ).not_to raise_error
        end
      end

    end

    after(:all) do
      @client.node.delete("slave")
    end
  end
end
