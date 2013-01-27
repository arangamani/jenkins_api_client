require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client do
  context "With valid credentials given" do
    before do
      @client = JenkinsApi::Client.new(
        :server_ip => '127.0.0.1',
        :server_port => 8080,
        :username => 'username',
        :password => 'password'
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
    end

    describe "#debug" do
      it "The default for debug should be false" do
        client = JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password'
        )
        client.debug.should == false
      end

      it "Should be able to set the debug value" do
        client = JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password',
          :debug => true
          )
        client.debug.should == true
      end

      it "Should be able to toggle the debug value" do
        client = JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password',
          :debug => true
          )
        client.toggle_debug
        client.debug.should == false
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
      describe "#getroot" do
        it "is defined with no parameters" do
          expect(
            lambda { @client.get_root }
          ).not_to raise_error(NoMethodError)
        end
      end

      describe "#api_get_request" do
        it "defined and should accept url_prefix, tree, and url_suffix" do
          expect(
            lambda { @client.api_get_request("/some/prefix", "tree", "/json") }
          ).not_to raise_error(NoMethodError)
        end
      end

      describe "#api_post_request" do
        it "is defined and should accept url_prefix" do
          expect(
            lambda { @client.api_post_request("/some/prefix") }
          ).not_to raise_error(NoMethodError)
        end
      end

      describe "#get_config" do
        it "is defined and should accept url_prefix" do
          expect(
            lambda { @client.get_config("/some/prefix") }
          ).not_to raise_error(NoMethodError)
        end
      end

      describe "#post_config" do
        it "is defined and should accept url_prefix and xml" do
          expect(
            lambda { @client.post_config("/some/prefix", "<tag></tag>") }
          ).not_to raise_error(NoMethodError)
        end
      end
    end
  end

  context "With some required parameters missing" do
    context "#initialize" do
      it "Should fail if server_ip is missing" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :bogus => '127.0.0.1',
              :server_port => 8080,
              :username => 'username',
              :password => 'password'
            })
          end
        ).to raise_error
      end

      it "Should fail if username is missing" do
        expect(
          lambda do
            JenkinsApi::Client.new({
              :server_ip => '127.0.0.1',
              :server_port => 8080,
              :bogus => 'username',
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
    end
  end
end
