require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client do
  context "With valid credentials given" do
    before do
      @client = JenkinsApi::Client.new(
        :server_ip => '127.0.0.1',
        :server_port => 8080,
        :username => 'username',
        :password => 'password',
        :log_location => '/dev/null'
      )
    end

    describe "#initialize" do
      it "initializes without exception" do
        expect(
          lambda do
            JenkinsApi::Client.new(
              :server_ip => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :password => 'password'
            )
          end
        ).not_to raise_error
      end

      it "initialize without exception if username/password not specified" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :server_ip => '127.0.0.1',
              :server_port => 8080
            })
          end
        ).not_to raise_error
      end

      it "initializes with server_url without exception" do
        expect(
          lambda do
            JenkinsApi::Client.new(
              :server_url => 'http://localhost',
              :username => 'username',
              :password => 'password'
            )
          end
        ).not_to raise_error
      end

      it "initializes the username and password from server_url" do
        client = JenkinsApi::Client.new(
          :server_url => 'http://someuser:asdf@localhost'
        )

        client.instance_variable_get('@username').should == 'someuser'
        client.instance_variable_get('@password').should == 'asdf'
      end

      it "uses explicit username, password over one in the server_url" do
        client = JenkinsApi::Client.new(
          :server_url => 'http://someuser:asdf@localhost',
          :username => 'otheruser',
          :password => '1234'
        )

        client.instance_variable_get('@username').should == 'otheruser'
        client.instance_variable_get('@password').should == '1234'
      end

      it "initializes with proxy args without exception" do
        expect(
          lambda do
            JenkinsApi::Client.new(
              :server_ip => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :password => 'password',
              :proxy_ip => '127.0.0.1',
              :proxy_port => 8081
            )
          end
        ).not_to raise_error
      end

      it "errors on bad proxy args" do
        expect(
          lambda do
            JenkinsApi::Client.new(
              :server_ip => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :password => 'password',
              :proxy_ip => '127.0.0.1'
            )
          end
        ).to raise_error
      end
    end

    describe "#SubClassAccessorMethods" do
      describe "#job" do
        it "Should return a Client::Job object" do
          client = JenkinsApi::Client.new(
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password'
            )
          client.job.class.should == JenkinsApi::Client::Job
        end
      end

      describe "#node" do
        it "Should return a Client::Node object" do
          client = JenkinsApi::Client.new(
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password'
            )
          client.node.class.should == JenkinsApi::Client::Node
        end
      end

      describe "#view" do
        it "Should return a Client::View object" do
          client = JenkinsApi::Client.new(
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password'
            )
          client.view.class.should == JenkinsApi::Client::View
        end
      end

      describe "#system" do
        it "Should return a Client::System object" do
          client = JenkinsApi::Client.new(
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password'
          )
          client.system.class.should == JenkinsApi::Client::System
        end
      end

      describe "#queue" do
        it "Should return a Client::BuildQueue object" do
          client = JenkinsApi::Client.new(
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password'
          )
          client.queue.class.should == JenkinsApi::Client::BuildQueue
        end
      end
    end

    describe "InstanceMethods" do
      describe "#get_root" do
        it "is defined with no parameters" do
          @client.respond_to?(:get_root).should be_true
          @client.method(:get_root).parameters.size.should == 0
        end
      end

      describe "#api_get_request" do
        it "defined and should accept url_prefix, tree, and url_suffix" do
          @client.respond_to?(:api_get_request).should be_true
          @client.method(:api_get_request).parameters.size.should == 4
        end
      end

      describe "#api_post_request" do
        it "is defined and should accept url_prefix" do
          @client.respond_to?(:api_post_request).should be_true
          @client.method(:api_post_request).parameters.size.should == 3
        end
      end

      describe "#get_config" do
        it "is defined and should accept url_prefix" do
          @client.respond_to?(:get_config).should be_true
          @client.method(:get_config).parameters.size.should == 1
        end
      end

      describe "#post_config" do
        it "is defined and should accept url_prefix and xml" do
          @client.respond_to?(:post_config).should be_true
          @client.method(:post_config).parameters.size.should == 2
        end

        it "sets the content type with charset as UTF-8 for the multi-byte content" do
          url_prefix   = '/prefix'
          xml          = '<dummy>dummy</dummy>'
          content_type = 'application/xml;charset=UTF-8'

          expect(@client).to receive(:post_data).with(url_prefix, xml, content_type)
          @client.post_config(url_prefix, xml)
        end
      end

      describe "#post_json" do
        it "is defined and should accept url_prefix and json" do
          @client.respond_to?(:post_json).should be_true
          @client.method(:post_json).parameters.size.should == 2
        end

        it "sets the content type with charset as UTF-8 for the multi-byte content" do
          url_prefix   = '/prefix'
          json         = '{ "dummy": "dummy" }'
          content_type = 'application/json;charset=UTF-8'

          expect(@client).to receive(:post_data).with(url_prefix, json, content_type)
          @client.post_json(url_prefix, json)
        end
      end

      describe "#get_jenkins_version" do
        it "is defined and accepts no parameters" do
          @client.respond_to?(:get_jenkins_version).should be_true
          @client.method(:get_jenkins_version).parameters.size.should == 0
        end
      end

      describe "#get_hudson_version" do
        it "is defined and accepts no parameters" do
          @client.respond_to?(:get_hudson_version).should be_true
          @client.method(:get_hudson_version).parameters.size.should == 0
        end
      end

      describe "#get_server_date" do
        it "is defined and accepts no parameters" do
          @client.respond_to?(:get_server_date).should be_true
          @client.method(:get_server_date).parameters.size.should == 0
        end
      end

      describe "#exec_script" do
        it "is defined and should accept script to execute" do
          @client.respond_to?(:exec_script).should be_true
          @client.method(:exec_script).parameters.size.should == 1
        end
      end

      describe "#exec_cli" do
        it "is defined and should execute the CLI" do
          @client.respond_to?(:exec_cli).should be_true
          @client.method(:exec_cli).parameters.size.should == 2
        end
      end

      describe "#deconstruct_version_string" do
        it "is defined and accepts a single param" do
          @client.respond_to?(:deconstruct_version_string).should be_true
          @client.method(:deconstruct_version_string).parameters.size.should == 1
        end

        it "takes a version string in the form 'a.b' and returns an array [a,b,c]" do
          TEST_2_PART_VERSION_STRING = "1.002"
          version = @client.deconstruct_version_string(TEST_2_PART_VERSION_STRING)
          version.should_not be_nil
          version.should_not be_empty
          version.size.should eql 3
          version[0].should eql 1
          version[1].should eql 2
          version[2].should eql 0
        end

        it "takes a version string in the form 'a.b.c' and returns an array [a,b]" do
          TEST_3_PART_VERSION_STRING = "1.002.3"
          version = @client.deconstruct_version_string(TEST_3_PART_VERSION_STRING)
          version.should_not be_nil
          version.should_not be_empty
          version.size.should eql 3
          version[0].should eql 1
          version[1].should eql 2
          version[2].should eql 3
        end

        it "should fail if parameter is not a string" do
          expect(
            lambda { @client.deconstruct_version_string(1) }
          ).to raise_error(NoMethodError) # match for fixnum
        end

        it "should return nil if parameter is not a string in the form '\d+.\d+(.\d+)'" do
          @client.deconstruct_version_string("A.B").should be_nil
          @client.deconstruct_version_string("1").should be_nil
          @client.deconstruct_version_string("1.").should be_nil
          @client.deconstruct_version_string("1.2.3.4").should be_nil
        end
      end

      describe "#compare_versions" do
        it "is defined and accepts two params" do
          @client.respond_to?(:compare_versions).should be_true
          @client.method(:compare_versions).parameters.size.should == 2
        end

        it "should correctly compare version numbers" do
          @client.compare_versions("1.0", "1.0").should eql(0)
          @client.compare_versions("1.0", "1.1").should eql(-1)
          @client.compare_versions("1.1", "1.0").should eql(1)
          @client.compare_versions("2.0", "1.99").should eql(1)
          @client.compare_versions("1.10", "1.2").should eql(1)

          @client.compare_versions("1.0.0", "1.0.0").should eql(0)
          @client.compare_versions("1.0", "1.0.1").should eql(-1)
          @client.compare_versions("1.1", "1.0.1").should eql(1)
          @client.compare_versions("2.0.0", "1.999.99").should eql(1)
          @client.compare_versions("1.0.10", "1.0.2").should eql(1)
        end
      end

      describe "#use_crumbs?" do
        it "returns true if the server has useCrumbs on" do
          expect(@client).to receive(:api_get_request).with("", "tree=useCrumbs") {
            {
              "useCrumbs" => true
            }
          }
          @client.use_crumbs?.should == true
        end

        it "returns false if the server has useCrumbs off" do
          expect(@client).to receive(:api_get_request).with("", "tree=useCrumbs") {
            {
              "useCrumbs" => false
            }
          }
          @client.use_crumbs?.should == false
        end
      end

      describe "#use_security?" do
        it "returns true if the server has useSecurity on" do
          expect(@client).to receive(:api_get_request).with("", "tree=useSecurity") {
            {
              "useSecurity" => true
            }
          }
          @client.use_security?.should == true
        end

        it "returns false if the server has useSecurity off" do
          expect(@client).to receive(:api_get_request).with("", "tree=useSecurity") {
            {
              "useSecurity" => false
            }
          }
          @client.use_security?.should == false
        end
      end
    end
  end

  context "With some required parameters missing" do
    context "#initialize" do
      it "Should fail if server_ip and server_url are missing" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :bogus => '127.0.0.1',
              :bogus_url => 'http://localhost',
              :server_port => 8080,
              :username => 'username',
              :password => 'password'
            })
          end
        ).to raise_error
      end

      it "Should fail if password is missing" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :server_ip => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :bogus => 'password'
            })
          end
        ).to raise_error
      end

      it "Should fail if proxy_ip is specified but proxy_port is not" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :bogus => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :password => 'password',
              :proxy_ip => '127.0.0.1',
            })
          end
        ).to raise_error
      end

      it "Should fail if proxy_port is specified but proxy_ip is not" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :bogus => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :password => 'password',
              :proxy_port => 8081,
            })
          end
        ).to raise_error
      end
    end
  end

  context "With logging configuration" do

    it "Should fail if logger is not a Logger object" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            :server_ip => '127.0.0.1',
            :logger    => 'testing',
          })
        end
      ).to raise_error
    end

    it "Should set logger instance variable to Logger" do
      client = JenkinsApi::Client.new(
        :server_ip => '127.0.0.1',
        :logger    => Logger.new(STDOUT),
      )

      client.instance_variable_get('@logger').class.should == Logger
    end

    it "Should fail if logger and log_level are both set" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            :server_ip => '127.0.0.1',
            :logger    => Logger.new(STDOUT),
            :log_level => Logger::INFO,
          })
        end
      ).to raise_error
    end

    it "Should fail if logger and log_location are both set" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            :server_ip    => '127.0.0.1',
            :logger       => Logger.new(STDOUT),
            :log_location => 'test.log',
          })
        end
      ).to raise_error
    end

  end
end
