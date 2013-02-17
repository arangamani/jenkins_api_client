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

      # Create a view that can be used for tests
      @client.view.create("general_purpose_view").to_i.should == 302
    end

    describe "InstanceMethods" do

      describe "#list" do
        it "Should be able to list all views" do
          @client.view.list.class.should == Array
        end
      end

      describe "#create" do
        it "accepts the name of the view and creates the view" do
          name = "test_view"
          @client.view.create(name).to_i.should == 302
          @client.view.list(name).include?(name).should be_true
          @client.view.delete(name).to_i.should == 302
        end
        it "accepts the name of view and creates a listview" do
          name = "test_view"
          @client.view.create(name, "listview").to_i.should == 302
          @client.view.list(name).include?(name).should be_true
          @client.view.delete(name).to_i.should == 302
        end
        it "accepts the name of view and creates a myview" do
          name = "test_view"
          @client.view.create(name, "myview").to_i.should == 302
          @client.view.list(name).include?(name).should be_true
          @client.view.delete(name).to_i.should == 302
        end
        it "raises an error when unsupported view type is specified" do
          expect(
            lambda { @client.view.create(name, "awesomeview") }
          ).to raise_error
        end
      end

      describe "#create_list_view" do

        def test_and_validate(params)
          name = params[:name]
          @client.view.create_list_view(params).to_i.should == 302
          @client.view.list(name).include?(name).should be_true
          @client.view.delete(name).to_i.should == 302
          @client.view.list(name).include?(name).should be_false
        end

        it "accepts just the name of the view and creates the view" do
          params = {
            :name => "test_list_view"
          }
          test_and_validate(params)
        end

        it "accepts description as an option" do
          params = {
            :name => "test_list_view",
            :description => "test list view created for functional test"
          }
          test_and_validate(params)
        end

        it "accepts filter_queue as an option" do
          params = {
            :name => "test_list_view",
            :filter_queue => true
          }
          test_and_validate(params)
        end

        it "accepts filter_executors as an option" do
          params = {
            :name => "test_list_view",
            :filter_executors => true
          }
          test_and_validate(params)
        end

        it "accepts regex as an option" do
          params = {
            :name => "test_list_view",
            :regex => "^test.*"
          }
          test_and_validate(params)
        end
      end

      describe "#delete" do
        name = "test_view_to_delete"
        before(:all) do
          @client.view.create(name).to_i.should == 302
        end
        it "accepts the name of the view and deletes from Jenkins" do
          @client.view.list(name).include?(name).should be_true
          @client.view.delete(name).to_i.should == 302
          @client.view.list(name).include?(name).should be_false
        end
      end

      describe "#list_jobs" do
        it "accepts the view name and lists all jobs in the view" do
          @client.view.list_jobs("general_purpose_view").class.should == Array
        end
      end

      describe "#exists?" do
        it "accepts the vie name and returns true if the view exists" do
          @client.view.exists?("general_purpose_view").should be_true
        end
      end

      describe "#add_job" do
        before(:all) do
          @client.job.create_freestyle(
            :name => "test_job_for_view"
          ).to_i.should == 200
        end
        it "accepts the job and and adds it to the specified view" do
          @client.view.add_job(
            "general_purpose_view",
            "test_job_for_view"
          ).to_i.should == 200
          @client.view.list_jobs(
            "general_purpose_view"
          ).include?("test_job_for_view").should be_true
        end
      end

      describe "#remove_job" do
        before(:all) do
          unless @client.job.exists?("test_job_for_view")
            @client.job.create_freestyle(
              :name => "test_job_for_view"
            ).to_i.should == 200
          end
          unless @client.view.list_jobs(
            "general_purpose_view").include?("test_job_for_view")
            @client.view.add_job(
              "general_purpose_job",
              "test_job_for_view"
            ).to_i.should == 200
          end
        end
        it "accepts the job name and removes it from the specified view" do
          @client.view.remove_job(
            "general_purpose_view",
            "test_job_for_view"
          ).to_i.should == 200
        end
      end

      describe "#get_config" do
        it "obtaines the view config.xml from the server" do
          expect(
            lambda { @client.view.get_config("general_purpose_view") }
          ).not_to raise_error
        end
      end

      describe "#post_config" do
        it "posts the given config.xml to the jenkins server's view" do
          expect(
            lambda {
              xml = @client.view.get_config("general_purpose_view")
              @client.view.post_config("general_purpose_view", xml)
            }
          ).not_to raise_error
        end
      end
    end

    after(:all) do
      @client.view.delete("general_purpose_view").to_i.should == 302
      if @client.job.exists?("test_job_for_view")
        @client.job.delete("test_job_for_view").to_i.should == 302
      end
    end

  end
end
