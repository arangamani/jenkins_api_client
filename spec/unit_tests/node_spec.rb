require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::Node do
  context "With properly initialized Client" do
    before do
      @client = mock
      @node = JenkinsApi::Client::Node.new(@client)
      @sample_json_computer_response = {
        "computer" => [
          "displayName" => "slave"
        ]
      }
      computer_sample_xml_filename = '../fixtures/files/computer_sample.xml'
      @sample_computer_xml = File.read(
        File.expand_path(computer_sample_xml_filename , __FILE__)
      )
    end

    describe "InstanceMethods" do

      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          expect(
            lambda{ JenkinsApi::Client::Node.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#list" do
        it "accepts filter and lists all nodes matching the filter" do
          @client.should_receive(
            :api_get_request
          ).and_return(
            @sample_json_computer_response
          )
          @node.list("slave").class.should == Array
        end
      end

      describe "GeneralAttributes" do
        general_attributes = JenkinsApi::Client::Node::GENERAL_ATTRIBUTES
        general_attributes.each do |attribute|
          describe "#get_#{attribute}" do
            it "should get the #{attribute} attribute" do
              @client.should_receive(
                :api_get_request
              ).and_return(
                @sample_json_computer_response
              )
              @node.method("get_#{attribute}").call
            end
          end
        end
      end

      describe "NodeProperties" do
        node_properties = JenkinsApi::Client::Node::NODE_PROPERTIES
        node_properties.each do |property|
          describe "#is_#{property}?" do
            it "should get the #{property} property" do
              @client.should_receive(
                :api_get_request
              ).twice.and_return(
                @sample_json_computer_response
              )
              @node.method("is_#{property}?").call("slave")
            end
          end
        end
      end

      describe "NodeAttributes" do
        node_attributes = JenkinsApi::Client::Node::NODE_ATTRIBUTES
        node_attributes.each do |attribute|
          describe "#get_node_#{attribute}" do
            it "should get the #{attribute} node attribute" do
              @client.should_receive(
                :api_get_request
              ).twice.and_return(
                @sample_json_computer_response
              )
              @node.method("get_node_#{attribute}").call("slave")
            end
          end
        end
      end

      describe "#get_config" do
        it "accepts the node name and obtains the config xml from the server" do
          @client.should_receive(
            :get_config
          ).with(
            "/computer/slave/config.xml"
          ).and_return(
            @sample_computer_xml
          )
          @node.get_config("slave")
        end
      end

      describe "#post_config" do
        it "accepts the node namd and config.xml and posts it to the server" do
          @client.should_receive(:post_config)
          @node.post_config("slave", @sample_computer_xml)
        end
      end

    end
  end
end
