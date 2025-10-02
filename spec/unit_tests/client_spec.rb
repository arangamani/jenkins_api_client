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
        JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password'
        )
      end

      it "initialize without exception if username/password not specified" do
        JenkinsApi::Client.new({
          :server_ip => '127.0.0.1',
          :server_port => 8080
        })
      end

      it "initializes with server_url without exception" do
        JenkinsApi::Client.new(
          :server_url => 'http://localhost',
          :username => 'username',
          :password => 'password'
        )
      end

      it "initializes the username and password from server_url" do
        client = JenkinsApi::Client.new(
          :server_url => 'http://someuser:asdf@localhost'
        )

        expect(client.instance_variable_get('@username')).to eq 'someuser'
        expect(client.instance_variable_get('@password')).to eq 'asdf'
      end

      it "uses explicit username, password over one in the server_url" do
        client = JenkinsApi::Client.new(
          :server_url => 'http://someuser:asdf@localhost',
          :username => 'otheruser',
          :password => '1234'
        )

        expect(client.instance_variable_get('@username')).to eq 'otheruser'
        expect(client.instance_variable_get('@password')).to eq '1234'
      end

      it "initializes with proxy args without exception" do
        JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password',
          :proxy_ip => '127.0.0.1',
          :proxy_port => 8081
        )
      end

      it "errors on bad proxy args" do
        expect {
          JenkinsApi::Client.new(
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password',
            :proxy_ip => '127.0.0.1'
          )
        }.to raise_error(ArgumentError)
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
          expect(client.job.class).to eq JenkinsApi::Client::Job
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
          expect(client.node.class).to eq JenkinsApi::Client::Node
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
          expect(client.view.class).to eq JenkinsApi::Client::View
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
          expect(client.system.class).to eq JenkinsApi::Client::System
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
          expect(client.queue.class).to eq JenkinsApi::Client::BuildQueue
        end
      end
    end

    describe "#root" do
      it "Should return a Client::Root object" do
        client = JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password'
        )
        expect(client.root.class).to eq JenkinsApi::Client::Root
      end
    end

    describe "InstanceMethods" do
      describe "#get_root" do
        it "is defined with no parameters" do
          expect(@client.respond_to?(:get_root)).to be_truthy
          expect(@client.method(:get_root).parameters.size).to eq 0
        end
      end

      describe "#api_get_request" do
        it "defined and should accept url_prefix, tree, and url_suffix" do
          expect(@client.respond_to?(:api_get_request)).to be_truthy
          expect(@client.method(:api_get_request).parameters.size).to eq 4
        end

        it "can parse deeply nested response" do
          stub_request(:get, "http://127.0.0.1:8080/api/json").to_return(body: ("[" * 101) + "1" + ("]" * 101))
          expect(@client.api_get_request("").flatten).to eq [1]
        end
      end

      describe "#api_post_request" do
        it "is defined and should accept url_prefix" do
          expect(@client.respond_to?(:api_post_request)).to be_truthy
          expect(@client.method(:api_post_request).parameters.size).to eq 3
        end
      end

      describe "#get_config" do
        it "is defined and should accept url_prefix" do
          expect(@client.respond_to?(:get_config)).to be_truthy
          expect(@client.method(:get_config).parameters.size).to eq 1
        end
      end

      describe "#post_config" do
        it "is defined and should accept url_prefix and xml" do
          expect(@client.respond_to?(:post_config)).to be_truthy
          expect(@client.method(:post_config).parameters.size).to eq 2
        end

        it "sets the content type with charset as UTF-8 for the multi-byte content" do
          url_prefix = '/prefix'
          xml = '<dummy>dummy</dummy>'
          content_type = 'application/xml;charset=UTF-8'

          expect(@client).to receive(:post_data).with(url_prefix, xml, content_type)
          @client.post_config(url_prefix, xml)
        end
      end

      describe "#post_json" do
        it "is defined and should accept url_prefix and json" do
          expect(@client.respond_to?(:post_json)).to be_truthy
          expect(@client.method(:post_json).parameters.size).to eq 2
        end

        it "sets the content type with charset as UTF-8 for the multi-byte content" do
          url_prefix = '/prefix'
          json = '{ "dummy": "dummy" }'
          content_type = 'application/json;charset=UTF-8'

          expect(@client).to receive(:post_data).with(url_prefix, json, content_type)
          @client.post_json(url_prefix, json)
        end
      end

      describe "#get_jenkins_version" do
        it "is defined and accepts no parameters" do
          expect(@client.respond_to?(:get_jenkins_version)).to be_truthy
          expect(@client.method(:get_jenkins_version).parameters.size).to eq 0
        end
      end

      describe "#get_hudson_version" do
        it "is defined and accepts no parameters" do
          expect(@client.respond_to?(:get_hudson_version)).to be_truthy
          expect(@client.method(:get_hudson_version).parameters.size).to eq 0
        end
      end

      describe "#get_server_date" do
        it "is defined and accepts no parameters" do
          expect(@client.respond_to?(:get_server_date)).to be_truthy
          expect(@client.method(:get_server_date).parameters.size).to eq 0
        end
      end

      describe "#exec_script" do
        it "is defined and should accept script to execute" do
          expect(@client.respond_to?(:exec_script)).to be_truthy
          expect(@client.method(:exec_script).parameters.size).to eq 1
        end
      end

      describe "#exec_cli" do
        it "is defined and should execute the CLI" do
          expect(@client.respond_to?(:exec_cli)).to be_truthy
          expect(@client.method(:exec_cli).parameters.size).to eq 2
        end
      end

      describe "#deconstruct_version_string" do
        it "is defined and accepts a single param" do
          expect(@client.respond_to?(:deconstruct_version_string)).to be_truthy
          expect(@client.method(:deconstruct_version_string).parameters.size).to eq 1
        end

        it "takes a version string in the form 'a.b' and returns an array [a,b,c]" do
          TEST_2_PART_VERSION_STRING = "1.002"
          version = @client.deconstruct_version_string(TEST_2_PART_VERSION_STRING)
          expect(version).to_not be_nil
          expect(version).to_not be_empty
          expect(version.size).to eql 3
          expect(version[0]).to eql 1
          expect(version[1]).to eql 2
          expect(version[2]).to eql 0
        end

        it "takes a version string in the form 'a.b.c' and returns an array [a,b]" do
          TEST_3_PART_VERSION_STRING = "1.002.3"
          version = @client.deconstruct_version_string(TEST_3_PART_VERSION_STRING)
          expect(version).to_not be_nil
          expect(version).to_not be_empty
          expect(version.size).to eql 3
          expect(version[0]).to eql 1
          expect(version[1]).to eql 2
          expect(version[2]).to eql 3
        end

        it "should fail if parameter is not a string" do
          expect { @client.deconstruct_version_string(1) }.to raise_error(NoMethodError) # match for fixnum
        end

        it "should return nil if parameter is not a string in the form '\d+.\d+(.\d+)'" do
          expect(@client.deconstruct_version_string("A.B")).to be_nil
          expect(@client.deconstruct_version_string("1")).to be_nil
          expect(@client.deconstruct_version_string("1.")).to be_nil
          expect(@client.deconstruct_version_string("1.2.3.4")).to be_nil
        end
      end

      describe "#compare_versions" do
        it "is defined and accepts two params" do
          expect(@client.respond_to?(:compare_versions)).to be_truthy
          expect(@client.method(:compare_versions).parameters.size).to eq 2
        end

        it "should correctly compare version numbers" do
          expect(@client.compare_versions("1.0", "1.0")).to eql(0)
          expect(@client.compare_versions("1.0", "1.1")).to eql(-1)
          expect(@client.compare_versions("1.1", "1.0")).to eql(1)
          expect(@client.compare_versions("2.0", "1.99")).to eql(1)
          expect(@client.compare_versions("1.10", "1.2")).to eql(1)

          expect(@client.compare_versions("1.0.0", "1.0.0")).to eql(0)
          expect(@client.compare_versions("1.0", "1.0.1")).to eql(-1)
          expect(@client.compare_versions("1.1", "1.0.1")).to eql(1)
          expect(@client.compare_versions("2.0.0", "1.999.99")).to eql(1)
          expect(@client.compare_versions("1.0.10", "1.0.2")).to eql(1)
        end
      end

      describe "#use_crumbs?" do
        it "returns true if the server has useCrumbs on" do
          expect(@client).to receive(:api_get_request).with("", "tree=useCrumbs") {
            {
              "useCrumbs" => true
            }
          }
          expect(@client.use_crumbs?).to eq true
        end

        it "returns false if the server has useCrumbs off" do
          expect(@client).to receive(:api_get_request).with("", "tree=useCrumbs") {
            {
              "useCrumbs" => false
            }
          }
          expect(@client.use_crumbs?).to eq false
        end
      end

      describe "#use_security?" do
        it "returns true if the server has useSecurity on" do
          expect(@client).to receive(:api_get_request).with("", "tree=useSecurity") {
            {
              "useSecurity" => true
            }
          }
          expect(@client.use_security?).to eq true
        end

        it "returns false if the server has useSecurity off" do
          expect(@client).to receive(:api_get_request).with("", "tree=useSecurity") {
            {
              "useSecurity" => false
            }
          }
          expect(@client.use_security?).to eq false
        end
      end
    end
  end

  context "With some required parameters missing" do
    context "#initialize" do
      it "Should fail if server_ip and server_url are missing" do
        expect {
          JenkinsApi::Client.new({
            :bogus => '127.0.0.1',
            :bogus_url => 'http://localhost',
            :server_port => 8080,
            :username => 'username',
            :password => 'password'
          })
        }.to raise_error(ArgumentError)
      end

      it "Should fail if password is missing" do
        expect {
          JenkinsApi::Client.new({
            :server_ip => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :bogus => 'password'
          })
        }.to raise_error(ArgumentError)
      end

      it "Should fail if proxy_ip is specified but proxy_port is not" do
        expect {
          JenkinsApi::Client.new({
            :bogus => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password',
            :proxy_ip => '127.0.0.1',
          })
        }.to raise_error(ArgumentError)
      end

      it "Should fail if proxy_port is specified but proxy_ip is not" do
        expect {
          JenkinsApi::Client.new({
            :bogus => '127.0.0.1',
            :server_port => 8080,
            :username => 'username',
            :password => 'password',
            :proxy_port => 8081,
          })
        }.to raise_error(ArgumentError)
      end
    end
  end

  context "With logging configuration" do

    it "Should fail if logger is not a Logger object" do
      expect {
        JenkinsApi::Client.new({
          :server_ip => '127.0.0.1',
          :logger => 'testing',
        })
      }.to raise_error(ArgumentError)
    end

    it "Should set logger instance variable to Logger" do
      client = JenkinsApi::Client.new(
        :server_ip => '127.0.0.1',
        :logger => Logger.new(STDOUT),
      )

      expect(client.instance_variable_get('@logger').class).to eq Logger
    end

    it "Should fail if logger and log_level are both set" do
      expect {
        JenkinsApi::Client.new({
          :server_ip => '127.0.0.1',
          :logger => Logger.new(STDOUT),
          :log_level => Logger::INFO,
        })
      }.to raise_error(ArgumentError)
    end

    it "Should fail if logger and log_location are both set" do
      expect {
        JenkinsApi::Client.new({
          :server_ip => '127.0.0.1',
          :logger => Logger.new(STDOUT),
          :log_location => 'test.log',
        })
      }.to raise_error(ArgumentError)
    end
  end
end
