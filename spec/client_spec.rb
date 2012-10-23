require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client do
  context "Given valid credentials and server information in the ~/.jenkins_api_client/login.yml" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/login.yml'
      begin
        @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    it "Should be able to initialize with valid credentials" do
      client1 = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      client1.class.should == JenkinsApi::Client
    end

    it "Should return a job object on call to job function" do
      @client.job.class.should == JenkinsApi::Client::Job
    end

    it "Should accept a YAML argument when creating a new client" do
      client2 = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      client2.class.should == JenkinsApi::Client
    end
    
  end
end
