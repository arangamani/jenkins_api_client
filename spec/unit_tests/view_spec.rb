require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::View do
  context "With properly initialized Client" do
    before do
      @client = mock
      @view = JenkinsApi::Client::View.new(@client)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instane of client object" do
          expect(
            lambda { JenkinsApi::Client::View.new(@client) }
          ).not_to raise_error
        end
      end
    end

  end
end
