require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::QueueItem do
  context "With properly initialized Client" do
    before do
      @client = double
      mock_logger = Logger.new "/dev/null"
      allow(@client).to receive(:logger).and_return(mock_logger)
      @sample_queue_item_json = { 
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
        "params" => "\nPARAM1=VALUE1\nPARAM2=VALUE2",
        "stuck" => false,
        "task" => {
          "name" => "queue_test",
          "url" => "http://localhost:8080/job/queue_test/",
          "color" => "grey_anime"
        },
        "why" => "Build #1 is already in progress (ETA:N/A)",
        "buildStartMilliseconds" => 1362906942832
      }
      @queue_item = JenkinsApi::Client::QueueItem.new(@client, @sample_queue_item_json)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object and queue json" do
          expect(
            lambda{ JenkinsApi::Client::QueueItem.new(@client, @sample_queue_item_json) }
          ).not_to raise_error
        end
      end

      describe "#id" do
        it "returns the queue id" do
            @queue_item.id.should == 2
        end
      end

      describe "#name" do
        it "returns the tasks name" do
            @queue_item.name.should == "queue_test"
        end
      end

      describe "#params" do
        it "returns the tasks params" do
            @queue_item.params.class.should == Hash
            @queue_item.params.should == {'PARAM1' => 'VALUE1', 'PARAM2' => 'VALUE2'}
        end
      end

      describe "#cancel" do
        it "signals jenkins to cancel queued item" do
            @client.should_receive(:api_post_request).with('/queue/cancelItem?id=2')
            @queue_item.cancel
        end
      end

    end
  end
end
