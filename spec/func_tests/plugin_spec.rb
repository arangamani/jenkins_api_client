#
# Specifying JenkinsApi::Client::View class capabilities
# Author Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::View do
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
    end

    describe "InstanceMethods" do
      describe "#list_installed" do
        it "lists all installed plugins in jenkins" do
          @client.plugin.list_installed.class.should == Hash
        end
        it "lists all installed plugins except bundled ones in jenkins" do
          @client.plugin.list_installed(true).class.should == Hash
        end
      end

      describe "#list_by_criteria" do
        supported_criteria = [
          "active", "bundled", "deleted", "downgradable", "enabled",
          "hasUpdate", "pinned"
        ]
        supported_criteria.each do |criteria|
          it "lists all installed plugins matching criteria '#{criteria}'" do
            @client.plugin.list_by_criteria(criteria).class.should == Hash
          end
        end
        it "raises an error if unsupported criteria is specified" do
          expect(
            lambda { @client.plugin.list_by_criteria("unsupported") }
          ).to raise_error(ArgumentError)
        end
      end

      describe "#list_available" do
        it "lists all available plugins in jenkins update center" do
          @client.plugin.list_available.class.should == Hash
        end
      end

      describe "#list_updates" do
        it "lists all available plugin updates in jenkins update center" do
          @client.plugin.list_updates.class.should == Hash
        end
      end
    end
  end
end
