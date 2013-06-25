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
          client2 = JenkinsApi::Client.new(
            :server_ip => @server_ip,
            :username => 'stranger',
            :password => 'hacked',
            :log_location => '/dev/null'
          )
          expect(
            lambda { client2.job.list_all }
          ).to raise_error(JenkinsApi::Exceptions::UnautherizedException)
        end
      end
      describe "#get_jenkins_version" do
        it "Should the jenkins version" do
          @client.get_jenkins_version.class.should == String
        end
      end

      describe "#get_hudson_version" do
        it "Should get the hudson version" do
          @client.get_hudson_version.class.should == String
        end
      end

      describe "#get_server_date" do
        it "Should return the server date" do
          @client.get_server_date.class.should == String
        end
      end
    end

    describe "SubClassAccessorMethods" do
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

      describe "#queue" do
        it "Should return a build queue object on call" do
          @client.queue.class.should == JenkinsApi::Client::BuildQueue
        end
      end
    end

  end
end
