#
# Specifying JenkinsApi::Client::PluginManager class capabilities
# Author Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::PluginManager do
  context "With properly initialized client" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/spec.yml'
      @valid_post_responses = [200, 201, 302]
      @test_plugin = "scripttrigger"
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
        supported_filters = [
          :active, :bundled, :deleted, :downgradable, :enabled,
          :hasUpdate, :pinned
        ]
        supported_filters.each do |filter|
          it "lists all installed plugins matching filter '#{filter}'" do
            @client.plugin.list_installed(filter => true).class.should == Hash
          end
        end
        it "raises an error if unsupported filter is specified" do
          expect(
            lambda { @client.plugin.list_installed(:unsupported => true) }
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

      describe "#install, #restart_required?" do
        it "installs a single plugin given as a string" do
          @client.plugin.install(@test_plugin)
          # Plugin installation might take a bit
          sleep 5
          @client.system.restart(true) if @client.plugin.restart_required?
          @client.system.wait_for_ready
          @client.plugin.list_installed.keys.should include(@test_plugin)
        end
        it "installs multiple plugins given as an array" do
          @client.plugin.install(@test_plugins)
          # Plugin installation might take a bit
          sleep 5
          @client.system.restart(true) if @client.plugin.restart_required?
          @client.system.wait_for_ready
          installed = @client.plugin.list_installed.keys
          @test_plugins.all? { |plugin| installed.include?(plugin) }.
            should == true
        end
      end

      describe "#uninstall, #restart_required?" do
        it "uninstalls a single plugin given as a string" do
          @client.plugin.uninstall(@test_plugin)
          # Plugin uninstallation might take a bit
          sleep 5
          @client.system.restart(true) if @client.plugin.restart_required?
          @client.system.wait_for_ready
          @client.plugin.list_installed.keys.should_not include(@test_plugin)
        end
        it "uninstalls multiple plugins given as an array" do
          @client.plugin.uninstall(@test_plugins)
          # Plugin uninstallation might take a bit
          sleep 5
          @client.system.restart(true) if @client.plugin.restart_required?
          @client.system.wait_for_ready
          installed = @client.plugin.list_installed.keys
          @test_plugins.all? { |plugin| installed.include?(plugin) }.
            should == false
        end
      end
    end
  end
end
