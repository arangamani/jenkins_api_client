#
# Specifying JenkinsApi::Client::System class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::System do
  context "With properly initialized client" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/login.yml'
      begin
        @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    it "Should be able to quiet down a Jenkins server" do
      @client.system.quiet_down.to_i.should == 302
    end

    it "Should be able to cancel the quiet down a Jenkins server" do
      @client.system.cancel_quiet_down.to_i.should == 302
    end

    it "Should be able to restart a Jenkins server safely" do
      @client.system.restart.to_i.should == 302
    end

    it "Should be able to wait after a safe restart" do
      @client.system.wait_for_ready.should == true
    end

    it "Should be able to force restart a Jenkins server" do
      @client.system.restart(true).to_i.should == 302
    end

    it "Should be able to wait after a force restart" do
      @client.system.wait_for_ready.should == true
    end

  end
end
