require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::Root do
  context "With properly initialized Client" do
    before do
      mock_logger = Logger.new "/dev/null"
      @client = double
      @client.should_receive(:logger).and_return(mock_logger)
      @root = JenkinsApi::Client::Root.new(@client)
      @sample_root_json1 = {
        "description" => "Hello Users",
        "primaryView" => [
            "name" => "default_view",
            "url" => "http://buildsystem:9999/jenkins"
        ],
        "quietingDown" => false,
        "useCrumbs" => "true",
        "useSecurity" => "true"
      }
      @sample_root_json2 = {
        "quietingDown" => true
      }
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          @client.should_receive(:logger).and_return(mock_logger)
          expect(
            lambda { JenkinsApi::Client::Root.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#quieting_down?" do
        it "returns false if jenkins is jenkins is not quieting down" do
          allow(@client).to receive(:api_get_request).with('', 'tree=quietingDown').and_return(@sample_root_json1)
          expect @root.quieting_down?.should be false
        end

        it "returns true if jenkins quieting down" do
          allow(@client).to receive(:api_get_request).with('', 'tree=quietingDown').and_return(@sample_root_json2)
          expect @root.quieting_down?.should be true
        end
      end

      describe "#description" do
        it "gets the message displayed to users on the home page" do
          allow(@client).to receive(:api_get_request).with('', 'tree=description').and_return(@sample_root_json1)
          expect @root.description.should == "Hello Users"
        end
      end
    end
  end
end
