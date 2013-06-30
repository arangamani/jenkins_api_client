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
      @test_plugin = "extensible-choice-parameter"
      @test_plugins = ["text-finder", "terminal", "warnings"]
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

      describe "#install" do
        it "installs a single plugin given as a string" do
          @client.plugin.install(@test_plugin)
          @client.system.restart(true) if @client.plugin.restart_required?
          sleep 10
          @client.system.wait_for_ready
          @client.plugin.list_installed.keys.should include(@test_plugin)
        end
        it "installs multiple plugins given as an array" do
          @client.plugin.install(@test_plugins)
          @client.system.restart(true) if @client.plugin.restart_required?
          sleep 10
          @client.system.wait_for_ready
          installed = @client.plugin.list_installed.keys
          @test_plugins.all? { |plugin| installed.include?(plugin) }.
            should == true
        end
      end

      describe "#uninstall" do
        it "uninstalls a single plugin given as a string" do
          @client.plugin.uninstall(@test_plugin)
          @client.system.restart(true) if @client.plugin.restart_required?
          sleep 10
          @client.system.wait_for_ready
          @client.plugin.list_installed.keys.should_not include(@test_plugin)
        end
        it "uninstalls multiple plugins given as an array" do
          @client.plugin.uninstall(@test_plugins)
          @client.system.restart(true) if @client.plugin.restart_required?
          sleep 10
          @client.system.wait_for_ready
          installed = @client.plugin.list_installed.keys
          @test_plugins.all? { |plugin| installed.include?(plugin) }.
            should == false
        end
      end
    end
  end
end
