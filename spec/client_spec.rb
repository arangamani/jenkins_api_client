#
# Specifying JenkinsApi::Client class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client do
  context "Given valid credentials and server information in the ~/.jenkins_api_client/login.yml" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/login.yml'
      # Grabbing just the server IP in a variable so we can check for wrong credentials
      @server_ip = YAML.load_file(File.expand_path(@creds_file, __FILE__))[:server_ip]
      begin
        @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    it "Should be able to toggle the debug value" do
      value = @client.debug
      @client.toggle_debug.should_not == value
    end

    it "Should be able to initialize with valid credentials" do
      client1 = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      client1.class.should == JenkinsApi::Client
    end

    it "Should fail if wrong credentials are given" do
      begin
        client2 = JenkinsApi::Client.new(:server_ip => @server_ip, :username => 'stranger', :password => 'hacked')
        client2.job.list_all
      rescue Exception => e
        e.class.should == JenkinsApi::Exceptions::UnautherizedException
      end
    end

    it "Should return a job object on call to job function" do
      @client.job.class.should == JenkinsApi::Client::Job
    end

    it "Should accept a YAML argument when creating a new client" do
      client3 = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      client3.class.should == JenkinsApi::Client
    end

  end
end
