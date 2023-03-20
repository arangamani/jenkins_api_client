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
          expect(@valid_post_responses).to  include(
            @client.system.quiet_down.to_i
          )
        end
      end

      describe "#cancel_quiet_down" do
        it "Should be able to cancel the quiet down a Jenkins server" do
          expect(@valid_post_responses).to  include(
            @client.system.cancel_quiet_down.to_i
          )
        end
      end

      describe "#restart" do
        it "Should be able to restart a Jenkins server safely" do
          expect(@valid_post_responses).to  include(
            @client.system.restart.to_i
          )
        end

        it "Should be able to wait after a safe restart" do
          expect(@client.system.wait_for_ready).to eq true
        end

        it "Should be able to force restart a Jenkins server" do
          expect(@valid_post_responses).to  include(
            @client.system.restart(true).to_i
          )
        end

        it "Should be able to wait after a force restart" do
          expect(@client.system.wait_for_ready).to eq true
        end
      end

      describe "#reload" do
        it "Should be able to reload a Jenkins server" do
          expect(@valid_post_responses).to  include(
            @client.system.reload.to_i
          )
        end
        it "Should be able to wait after a force restart" do
          expect(@client.system.wait_for_ready).to eq true
        end
      end

      describe "#list_users" do
        it "Should be able to get a list of users" do
          expect(@client.system.list_users).to be_an_instance_of(Array)
        end
      end

    end

  end
end
