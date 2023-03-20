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

      # Create a view that can be used for tests
      @valid_post_responses.should include(
        @client.view.create("general_purpose_view").to_i
      )
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
          @valid_post_responses.should include(
            @client.view.create(name).to_i
          )
          @client.view.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
        end
        it "accepts spaces and other characters in the view name" do
          name = "test view with spaces and {special characters}"
          @valid_post_responses.should include(
            @client.view.create(name).to_i
          )
          @client.view.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
        end
        it "accepts the name of view and creates a listview" do
          name = "test_view"
          @valid_post_responses.should include(
            @client.view.create(name, "listview").to_i
          )
          @client.view.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
        end
        it "accepts the name of view and creates a myview" do
          name = "test_view"
          @valid_post_responses.should include(
            @client.view.create(name, "myview").to_i
          )
          @client.view.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
        end
        it "raises an error when unsupported view type is specified" do
          expect { @client.view.create(name, "awesomeview") }.to raise_error
        end
        it "raises proper error if the view already exists" do
          name = "duplicate_view"
          @valid_post_responses.should include(
            @client.view.create(name, "listview").to_i
          )
          @client.view.list(name).include?(name).should be_true
          expect { @client.view.create(name, "listview") }.to raise_error(JenkinsApi::Exceptions::ViewAlreadyExists)
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
        end
      end

      describe "#create_list_view" do

        def test_and_validate(params)
          name = params[:name]
          @valid_post_responses.should include(
            @client.view.create_list_view(params).to_i
          )
          @client.view.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
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
        it "raises an error when the input parameters is not a Hash" do
          expect {
              @client.view.create_list_view("a_string")
            }.to raise_error(ArgumentError)
        end
        it "raises an error when the required name paremeter is missing" do
          expect {
              @client.view.create_list_view(:description => "awesomeview")
            }.to raise_error(ArgumentError)
        end
      end

      describe "#delete" do
        name = "test_view_to_delete"
        before(:all) do
          @valid_post_responses.should include(
            @client.view.create(name).to_i
          )
        end
        it "accepts the name of the view and deletes from Jenkins" do
          @client.view.list(name).include?(name).should be_true
          @valid_post_responses.should include(
            @client.view.delete(name).to_i
          )
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
          @valid_post_responses.should include(
            @client.job.create_freestyle(
              :name => "test_job_for_view"
            ).to_i
          )
        end
        it "accepts the job and and adds it to the specified view" do
          @valid_post_responses.should include(
            @client.view.add_job(
              "general_purpose_view",
              "test_job_for_view"
            ).to_i
          )
          @client.view.list_jobs(
            "general_purpose_view"
          ).include?("test_job_for_view").should be_true
        end
      end

      describe "#remove_job" do
        before(:all) do
          unless @client.job.exists?("test_job_for_view")
            @valid_post_responses.should include(
              @client.job.create_freestyle(
                :name => "test_job_for_view"
              ).to_i
            )
          end
          unless @client.view.list_jobs(
            "general_purpose_view").include?("test_job_for_view")
            @valid_post_responses.should include(
              @client.view.add_job(
                "general_purpose_job",
                "test_job_for_view"
              ).to_i
            )
          end
        end
        it "accepts the job name and removes it from the specified view" do
          @valid_post_responses.should include(
            @client.view.remove_job(
              "general_purpose_view",
              "test_job_for_view"
            ).to_i
          )
        end
      end

      describe "#get_config" do
        it "obtaines the view config.xml from the server" do
          expect { @client.view.get_config("general_purpose_view") } .not_to raise_error
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
      @valid_post_responses.should include(
        @client.view.delete("general_purpose_view").to_i
      )
      if @client.job.exists?("test_job_for_view")
        @valid_post_responses.should include(
          @client.job.delete("test_job_for_view").to_i
        )
      end
    end
  end
end
