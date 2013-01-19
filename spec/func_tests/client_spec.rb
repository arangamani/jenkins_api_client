#
# Specifying JenkinsApi::Client class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client do
  context "Given valid credentials and server information are given" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/spec.yml'
      # Grabbing just the server IP in a variable so we can check
      # for wrong credentials
      @server_ip = YAML.load_file(
        File.expand_path(@creds_file, __FILE__)
      )[:server_ip]
      begin
        @client = JenkinsApi::Client.new(
          YAML.load_file(File.expand_path(@creds_file, __FILE__))
        )
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    describe "InstanceMethods" do

      describe "#debug" do
        it "Should be able to toggle the debug value" do
          value = @client.debug
          @client.toggle_debug.should_not == value
        end
      end

      describe "#initialize" do
        it "Should be able to initialize with valid credentials" do
          client1 = JenkinsApi::Client.new(
            YAML.load_file(File.expand_path(@creds_file, __FILE__))
          )
          client1.class.should == JenkinsApi::Client
        end

        it "Should accept a YAML argument when creating a new client" do
          client3 = JenkinsApi::Client.new(
            YAML.load_file(File.expand_path(@creds_file, __FILE__))
          )
          client3.class.should == JenkinsApi::Client
        end

        it "Should fail if wrong credentials are given" do
          begin
            client2 = JenkinsApi::Client.new(:server_ip => @server_ip,
                                             :username => 'stranger',
                                             :password => 'hacked')
            client2.job.list_all
          rescue Exception => e
            e.class.should == JenkinsApi::Exceptions::UnautherizedException
          end
        end
      end

      describe "#job" do
        it "Should return a job object on call" do
          @client.job.class.should == JenkinsApi::Client::Job
        end
      end

      describe "#node" do
        it "Should return a node object on call" do
          @client.node.class.should == JenkinsApi::Client::Node
        end
      end

      describe "#view" do
        it "Should return a view object on call" do
          @client.view.class.should == JenkinsApi::Client::View
        end
      end

      describe "#system" do
        it "Should return a system object on call" do
          @client.system.class.should == JenkinsApi::Client::System
        end
      end
    end

  end
end
