require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::BuildQueue do
  context "With properly initialized Client" do
    before do
      @client = double
      mock_logger = Logger.new "/dev/null"
      expect(@client).to receive(:logger).and_return(mock_logger)
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
          expect(@client).to receive(:logger).and_return(mock_logger)
          JenkinsApi::Client::BuildQueue.new(@client)
        end
      end

      describe "#size" do
        it "returns the size of the queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          @queue.size
        end
      end

      describe "#list" do
        it "returns the list of tasks in the queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.list.class).to eq Array
        end
      end

      describe "#get_age" do
        it "returns the age of a task" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.get_age("queue_test").class).to eq Float
        end
      end

      describe "#get_details" do
        it "returns the details of a task in the queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.get_details("queue_test").class).to eq Hash
        end
      end

      describe "#get_causes" do
        it "returns the causes of a task in queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.get_causes("queue_test").class).to eq Array
        end
      end

      describe "#get_reason" do
        it "returns the reason of a task in queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.get_reason("queue_test").class).to eq String
        end
      end

      describe "#get_eta" do
        it "returns the ETA of a task in queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.get_eta("queue_test").class).to eq String
        end
      end

      describe "#get_params" do
        it "returns the params of a task in queue" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.get_params("queue_test").class).to eq String
        end
      end

      describe "#is_buildable?" do
        it "returns true if the job is buildable" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.is_buildable?("queue_test")).to eq false
        end
      end

      describe "#is_blocked?" do
        it "returns true if the job is blocked" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.is_blocked?("queue_test")).to eq true
        end
      end

      describe "#is_stuck?" do
        it "returns true if the job is stuck" do
          expect(@client).to receive(:api_get_request).with("/queue").and_return(
            @sample_queue_json
          )
          expect(@queue.is_stuck?("queue_test")).to eq false
        end
      end

    end
  end
end
