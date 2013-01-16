require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::System do
  context "With properly initialized Client" do
    before do
      @client = mock
      @view = JenkinsApi::Client::System.new(@client)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          expect(
            lambda{ JenkinsApi::Client::System.new(@client) }
          ).not_to raise_error
        end
      end
    end

  end
end
