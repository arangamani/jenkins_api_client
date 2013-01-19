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

      describe "#list" do
        it "Should be able to list all views" do
          @client.view.list.class.should == Array
        end
      end

      describe "#get_config" do
        it "obtaines the view config.xml from the server" do
          #expect(
            #lambda { @client.view.get_config("slave") }
          #).not_to raise_error
        end
      end

      describe "#post_config" do
        it "posts the given config.xml to the jenkins server's view" do
          #expect(
            #lambda {
              #xml = @client.view.get_config("slave")
              #@client.view.post_config("slave", xml)
            #}
          #).not_to raise_error
        end
      end
      
    end
  end
end
