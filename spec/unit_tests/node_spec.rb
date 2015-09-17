require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::Node do
  context "With properly initialized Client" do
    before do
      @client = double
      mock_logger = Logger.new "/dev/null"
      @client.should_receive(:logger).and_return(mock_logger)
      @node = JenkinsApi::Client::Node.new(@client)
      @sample_json_list_response = {
        "computer" => [
          "displayName" => "slave"
        ]
      }
      @sample_json_computer_response = {
        "displayName" => "slave"
      }
      @offline_slave                 = {
        "displayName"        => "slave",
        "offline"            => true,
        "temporarilyOffline" => true,
      }
      @online_slave                  = {
        "displayName"        => "slave",
        "offline"            => false,
        "temporarilyOffline" => false,
      }
      @offline_slave_in_string       = {
        "displayName" => "slave",
        "offline"     => "true",
      }
      @online_slave_in_string        = {
        "displayName" => "slave",
        "offline"     => "false",
      }
      computer_sample_xml_filename = '../fixtures/files/computer_sample.xml'
      @sample_computer_xml = File.read(
        File.expand_path(computer_sample_xml_filename , __FILE__)
      )
    end

    describe "InstanceMethods" do

      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          @client.should_receive(:logger).and_return(mock_logger)
          expect(
            lambda{ JenkinsApi::Client::Node.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#create_dumb_slave" do
        it "creates a dumb slave by accepting required params" do
          @client.should_receive(:api_post_request).and_return("302")
          @node.create_dumb_slave(
            :name => "test_slave",
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          )
        end
        it "fails if name is not given" do
          expect(
            lambda{
              @node.create_dumb_slave(
                :slave_host => "10.10.10.10",
                :private_key_file => "/root/.ssh/id_rsa"
              )
            }
          ).to raise_error
        end
        it "fails if slave_host is not given" do
          expect(
            lambda{
              @node.create_dumb_slave(
                :name => "test_slave",
                :private_key_file => "/root/.ssh/id_rsa"
              )
            }
          ).to raise_error
        end
        it "fails if private_key_file is not given" do
          expect(
            lambda{
              @node.create_dumb_slave(
                :name => "test_slave",
                :slave_host => "10.10.10.10"
              )
            }
          ).to raise_error
        end
      end

      describe "#create_dump_slave" do

        it "just delegates to #create_dumb_slave" do
          @node.should_receive(:create_dumb_slave)
          @node.create_dump_slave(
            :name => "test_slave",
            :slave_host => "10.10.10.10",
            :private_key_file => "/root/.ssh/id_rsa"
          )
        end

      end
      describe "#delete" do
        it "gets the node name and deletes if exists" do
          slave_name = "slave"
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer"
          ).and_return(
            @sample_json_list_response
          )
          @client.should_receive(
            :api_post_request
          ).with(
            "/computer/#{slave_name}/doDelete"
          ).and_return(
            "302"
          )
          @node.delete(slave_name).to_i.should == 302
        end
        it "fails if the given node doesn't exist in Jenkins" do
          slave_name = "not_there"
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer"
          ).and_return(
            @sample_json_list_response
          )
          expect(
            lambda{ @node.delete(slave_name) }
          ).to raise_error
        end
      end

      describe "#list" do
        it "accepts filter and lists all nodes matching the filter" do
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer"
          ).and_return(
            @sample_json_list_response
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
              ).with(
                "/computer",
                "tree=#{attribute}[*[*[*]]]"
              ).and_return(
                @sample_json_list_response
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
              ).with(
                "/computer/slave",
                "tree=#{property}"
              ).and_return(
                @sample_json_computer_response
              )
              @node.method("is_#{property}?").call("slave")
            end

            it "should get the #{property} property for master" do
              @client.should_receive(
                :api_get_request
              ).with(
                "/computer/(master)",
                "tree=#{property}"
              ).and_return(
                @sample_json_computer_response
              )
              @node.method("is_#{property}?").call("master")
            end
          end
        end
      end

      describe 'is_offline?' do
        it "returns true if the node is offline" do
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer/slave",
            "tree=offline"
          ).and_return(
            @offline_slave
          )
          @node.method("is_offline?").call("slave").should be_true
        end

        it "returns false if the node is online" do
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer/slave",
            "tree=offline"
          ).and_return(
            @online_slave
          )
          @node.method("is_offline?").call("slave").should be_false
        end

        it "returns false if the node is online and have a string value on its attr" do
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer/slave",
            "tree=offline"
          ).and_return(
            @offline_slave_in_string
          )
          @node.method("is_offline?").call("slave").should be_true
        end

        it "returns false if the node is online and have a string value on its attr" do
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer/slave",
            "tree=offline"
          ).and_return(
            @online_slave_in_string
          )
          @node.method("is_offline?").call("slave").should be_false
        end
      end

      describe "NodeAttributes" do
        node_attributes = JenkinsApi::Client::Node::NODE_ATTRIBUTES
        node_attributes.each do |attribute|
          describe "#get_node_#{attribute}" do
            it "should get the #{attribute} node attribute" do
              @client.should_receive(
                :api_get_request
              ).with(
                "/computer/slave",
                "tree=#{attribute}[*[*[*]]]"
              ).and_return(
                @sample_json_computer_response
              )
              @node.method("get_node_#{attribute}").call("slave")
            end

            it "should get the #{attribute} node attribute for master" do
              @client.should_receive(
                :api_get_request
              ).with(
                "/computer/(master)",
                "tree=#{attribute}[*[*[*]]]"
              ).and_return(
                @sample_json_computer_response
              )
              @node.method("get_node_#{attribute}").call("master")
            end
          end
        end
      end

      describe "#get_config" do
        it "accepts the node name and obtains the config xml from the server" do
          @client.should_receive(:get_config).with(
            "/computer/slave"
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

      describe "#toggle_temporarilyOffline" do
        it "successfully toggles an offline status of a node" do
          @client.should_receive(:api_post_request).with(
            "/computer/slave/toggleOffline?offlineMessage=foo%20bar"
          ).and_return("302")
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer/slave",
            "tree=temporarilyOffline"
          ).and_return(
            @offline_slave,
            @online_slave
          )
          @node.method("toggle_temporarilyOffline").call("slave", "foo bar").should be_false
        end

        it "fails to toggle an offline status of a node" do
          @client.should_receive(:api_post_request).with(
            "/computer/slave/toggleOffline?offlineMessage=foo%20bar"
          ).and_return("302")
          @client.should_receive(
            :api_get_request
          ).with(
            "/computer/slave",
            "tree=temporarilyOffline"
          ).and_return(
            @online_slave,
            @online_slave
          )
          expect(
            lambda{
              @node.toggle_temporarilyOffline("slave", "foo bar")
            }
          ).to raise_error
        end
      end
    end
  end
end
