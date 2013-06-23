#
# Specifying JenkinsApi::Client::System class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::System do
  context "With properly initialized client" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/spec.yml'
      @valid_post_responses = [200, 201, 302]
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

      describe "#quiet_down" do
        it "Should be able to quiet down a Jenkins server" do
          @valid_post_responses.should include(
            @client.system.quiet_down.to_i
          )
        end
      end

      describe "#cancel_quiet_down" do
        it "Should be able to cancel the quiet down a Jenkins server" do
          @valid_post_responses.should include(
            @client.system.cancel_quiet_down.to_i
          )
        end
      end

      describe "#restart" do
        it "Should be able to restart a Jenkins server safely" do
          @valid_post_responses.should include(
            @client.system.restart.to_i
          )
        end

        it "Should be able to wait after a safe restart" do
          @client.system.wait_for_ready.should == true
        end

        it "Should be able to force restart a Jenkins server" do
          @valid_post_responses.should include(
            @client.system.restart(true).to_i
          )
        end

        it "Should be able to wait after a force restart" do
          @client.system.wait_for_ready.should == true
        end
      end

      describe "#reload" do
        it "Should be able to reload a Jenkins server" do
          @valid_post_responses.should include(
            @client.system.reload.to_i
          )
        end
        it "Should be able to wait after a force restart" do
          @client.system.wait_for_ready.should == true
        end
      end

      describe "#list_users" do
        it "Should be able to get a list of users" do
          @client.system.list_users.size == 1
        end
      end

    end

  end
end
