require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::System do
  context "With properly initialized Client" do
    before do
      @client = mock
      @system = JenkinsApi::Client::System.new(@client)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          expect(
            lambda{ JenkinsApi::Client::System.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#quiet_down" do
        it "sends a request to put the server in quiet down mode" do
          @client.should_receive(:api_post_request).with("/quietDown")
          @system.quiet_down
        end
      end

      describe "#cancel_quiet_down" do
        it "sends a request to take the server away from quiet down mode" do
          @client.should_receive(:api_post_request).with("/cancelQuietDown")
          @system.cancel_quiet_down
        end
      end

      describe "#restart" do
        it "sends a safe restart request to the server" do
          @client.should_receive(:api_post_request).with("/safeRestart")
          @system.restart(false)
        end
        it "sends a force restart request to the server" do
          @client.should_receive(:api_post_request).with("/restart")
          @system.restart(true)
        end
      end

      describe "#wait_for_ready" do
        it "exits if the response body doesn't have the wait message" do
          @client.should_receive(:get_root).and_return(Net::HTTP.get_response(URI('http://example.com/index.html')))
          @client.should_receive(:debug)
          @system.wait_for_ready
        end
      end

    end
  end
end
