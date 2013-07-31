#
# Specifying JenkinsApi::Client::User class capabilities
# Author: Doug Henderson <dougforpres@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::User do
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

      describe "#list_users" do
        it "Should be able to get a list of users" do
          @client.user.list_users.size.should == 1
        end
      end

      describe "#get_user" do
        it "Should be able to get a specific user" do
          # Actually, we're gonna get every user in the main user list
          users = @client.user.list_users

          users.each do |id, user|
            id.should eq(user['id'])
            fetched = @client.user.get_user(id)
            fetched.should eq(user)
          end
          
        end
      end

    end

  end
end
