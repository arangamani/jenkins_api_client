require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::View do
  context "With properly initialized Client" do
    before do
      mock_logger = Logger.new "/dev/null"
      @client = double
      expect(@client).to receive(:logger).and_return(mock_logger)
      @view = JenkinsApi::Client::View.new(@client)
      @sample_views_json = {
        "views" => [
          {"name" => "test_view"},
          {"name" => "test_view2"}
        ]
      }
      @sample_view_json = {
        "jobs" => [
          {"name" => "test_job"},
          {"name" => "test_job2"}
        ]
      }
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          expect(@client).to receive(:logger).and_return(mock_logger)
          expect { JenkinsApi::Client::View.new(@client) } .not_to raise_error
        end
      end

      describe "#create" do
        it "creates a view by accepting a name" do
          expect(@client).to receive(:api_post_request)
          @view.create("test_view")
        end
      end

      describe "#delete" do
        it "deletes the view with the given name" do
          expect(@client).to receive(:api_post_request).with("/view/test_view/doDelete")
          @view.delete("test_view")
        end
      end

      describe "#list" do
        it "lists all views" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          response = @view.list
          response.class.should == Array
          response.size.should == 2
        end

        it "lists views matching specific filter" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          response = @view.list("test_view2")
          response.class.should == Array
          response.size.should == 1
        end

        it "lists views matching specific filter and matches case" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          response = @view.list("TEST_VIEW", false)
          response.class.should == Array
          response.size.should == 0
        end
      end

      describe "#exists?" do
        it "returns true a view that exists" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          @view.exists?("test_view2").should == true
        end

        it "returns false for non-existent view" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          @view.exists?("i_am_not_there").should == false
        end
      end

      describe "#list_jobs" do
        it "lists all jobs in the given view" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          expect(@client).to receive(:api_get_request).with("/view/test_view").and_return(@sample_view_json)
          response = @view.list_jobs("test_view")
          response.class.should == Array
          response.size.should == 2
        end

        it "raises an error if called on a non-existent view" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          expect { @view.list_jobs("i_am_not_there") }.to raise_error
        end
      end

      describe "#list_jobs_with_details" do
        it "lists all jobs with details in the given view" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          expect(@client).to receive(:api_get_request).with("/view/test_view").and_return(
              @sample_view_json)
          response = @view.list_jobs_with_details("test_view")
          response.class.should == Array
          response.size.should == @sample_view_json["jobs"].size
        end

        it "raises an error if called on a non-existent view" do
          expect(@client).to receive(:api_get_request).with("", "tree=views[name]").and_return(@sample_views_json)
          expect { @view.list_jobs_with_details("i_am_not_there") }.to raise_error
        end
      end

      describe "#add_job" do
        it "adds the specified job to the specified view" do
          expect(@client).to receive(:api_post_request)
          @view.add_job("test_view", "test_job3")
        end
      end

      describe "#remove_job" do
        it "removes the specified job to the specified view" do
          expect(@client).to receive(:api_post_request)
          @view.remove_job("test_view", "test_job")
        end
      end

      describe "#get_config" do
        it "obtains the config from the server for the specified view" do
          expect(@client).to receive(:get_config).with("/view/test_view")
          @view.get_config("test_view")
        end
      end

      describe "#post_config" do
        it "posts the config to the server for the specified view" do
          expect(@client).to receive(:post_config).with("/view/test_view/config.xml", "<view>test_view</view>")
          @view.post_config("test_view", "<view>test_view</view>")
        end
      end

    end
  end
end
