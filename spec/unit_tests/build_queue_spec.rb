require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::BuildQueue do
  context "With properly initialized Client" do
    before do
      @client = mock
      mock_logger = Logger.new "/dev/null"
      @client.should_receive(:logger).and_return(mock_logger)
      @queue = JenkinsApi::Client::BuildQueue.new(@client)
      @sample_queue_json = {
        "items" => [
          {
            "actions" => [
              {
                "causes" => [
                  {

                  }
                ]
              }
            ],
            "blocked" => true,
            "buildable" => false,
            "id" => 2,
            "inQueueSince" => 1362906942731,
            "params" => "",
            "stuck" => false,
            "task" => {
              "name" => "queue_test",
              "url" => "http://localhost:8080/job/queue_test/",
              "color" => "grey_anime"
            },
            "why" => "Build #1 is already in progress (ETA:N/A)",
            "buildStartMilliseconds" => 1362906942832
          }
        ]
      }
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          @client.should_receive(:logger).and_return(mock_logger)
          expect(
            lambda{ JenkinsApi::Client::BuildQueue.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#size" do
        it "returns the size of the queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.size
        end
      end

      describe "#list" do
        it "returns the list of tasks in the queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.list.class.should == Array
        end
      end

      describe "#get_age" do
        it "returns the age of a task" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.get_age("queue_test").class.should == Float
        end
      end

      describe "#get_details" do
        it "returns the details of a task in the queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.get_details("queue_test").class.should == Hash
        end
      end

      describe "#get_causes" do
        it "returns the causes of a task in queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.get_causes("queue_test").class.should == Array
        end
      end

      describe "#get_reason" do
        it "returns the reason of a task in queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.get_reason("queue_test").class.should == String
        end
      end

      describe "#get_eta" do
        it "returns the ETA of a task in queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.get_eta("queue_test").class.should == String
        end
      end

      describe "#get_params" do
        it "returns the params of a task in queue" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.get_params("queue_test").class.should == String
        end
      end

      describe "#is_buildable?" do
        it "returns true if the job is buildable" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.is_buildable?("queue_test").should == false
        end
      end

      describe "#is_blocked?" do
        it "returns true if the job is blocked" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.is_blocked?("queue_test").should == true
        end
      end

      describe "#is_stuck?" do
        it "returns true if the job is stuck" do
          @client.should_receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.is_stuck?("queue_test").should == false
        end
      end

    end
  end
end
