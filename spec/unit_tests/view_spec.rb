require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::View do
  context "With properly initialized Client" do
    before do
      @client = mock
      @view = JenkinsApi::Client::View.new(@client)
      @sample_views_json = {
        "views" => [
          {"name" => "test_view"},
          {"name" => "test_view2"}
        ]
      }
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instane of client object" do
          expect(
            lambda { JenkinsApi::Client::View.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#create" do
        it "creates a view by accepting a name" do
          @client.should_receive(:api_post_request)
          @view.create("test_view")
        end
      end

      describe "#delete" do
        it "deletes the view with the given name" do
          @client.should_receive(:api_post_request).with("/view/test_view/doDelete")
          @view.delete("test_view")
        end
      end

      describe "#list" do
        it "lists all views" do
          @client.should_receive(:api_get_request).with("/").and_return(@sample_views_json)
          response = @view.list
          response.class.should == Array
          response.size.should == 2
        end

        it "lists views matching specific filter" do
          @client.should_receive(:api_get_request).with("/").and_return(@sample_views_json)
          response = @view.list("test_view2")
          response.class.should == Array
          response.size.should == 1
        end

        it "lists views matching specific filter and matches case" do
          @client.should_receive(:api_get_request).with("/").and_return(@sample_views_json)
          response = @view.list("TEST_VIEW", false)
          response.class.should == Array
          response.size.should == 0
        end
      end

      describe "#exists?" do
        it "returns true a view that exists" do
          @client.should_receive(:api_get_request).with("/").and_return(@sample_views_json)
          @view.exists?("test_view2").should == true
        end

        it "returns false for non-existent view" do
          @client.should_receive(:api_get_request).with("/").and_return(@sample_views_json)
          @view.exists?("i_am_not_there").should == false
        end
      end

      describe "#list_jobs" do

      end

      describe "#add_job" do

      end

      describe "#remove_job" do

      end

      describe "#get_config" do

      end

      describe "#post_config" do

      end

    end
  end
end
