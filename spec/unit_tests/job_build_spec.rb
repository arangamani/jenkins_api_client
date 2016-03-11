require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::JobBuild do
  context "With properly initialized Client" do
    before do
      @client = double
      mock_logger = Logger.new "/dev/null"
      allow(@client).to receive(:logger).and_return(mock_logger)
      @build = JenkinsApi::Client::JobBuild.new(@client, id: 23, name: 'build_test')
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object id and name" do
          expect(
            lambda{ JenkinsApi::Client::JobBuild.new(@client, id: 1, name: 'name') }
          ).not_to raise_error
        end
      end

      describe "#id" do
        it "returns the build id" do
          @build.id.should == 23
        end
      end

      describe "#name" do
        it "returns the build name" do
          @build.name.should == "build_test"
        end
      end

      describe "#params" do
        it "queries the server when asked about parameters of the build" do
          json = {
            'actions' => [
              [
                {
                  "name"  =>  "PARAM1",
                  "value" =>  "VALUE1",
                },
                {
                  "name"  =>  "PARAM2",
                  "value" =>  "VALUE2",
                }
              ]
            ]
          }
          @client.should_receive(:api_get_request).with('/job/build_test/23', anything()).once().and_return(json)
          2.times do
            @build.params.should == {'PARAM1' => 'VALUE1', 'PARAM2' => 'VALUE2'}
          end
        end

        it "queries the server when asked about parameters of the build (with other type of possible json response)" do
          json = {
            'actions' => [
              {
                'parameters' => [
                  {
                    "name"  =>  "PARAM1",
                    "value" =>  "VALUE1",
                  },
                  {
                    "name"  =>  "PARAM2",
                    "value" =>  "VALUE2",
                  }
                ]
              }
            ]
          }
          @client.should_receive(:api_get_request).with('/job/build_test/23', anything()).once().and_return(json)
          2.times do
            @build.params.should == {'PARAM1' => 'VALUE1', 'PARAM2' => 'VALUE2'}
          end
        end
      end
    end
  end
end
