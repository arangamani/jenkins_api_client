#
# Specifying JenkinsApi::Client class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client do
  context "Given valid credentials and server information are given" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/spec.yml'
      # Grabbing just the server IP in a variable so we can check
      # for wrong credentials
      @server_ip = YAML.load_file(
        File.expand_path(@creds_file, __FILE__)
      )[:server_ip]
      begin
        @client = JenkinsApi::Client.new(
          YAML.load_file(File.expand_path(@creds_file, __FILE__))
        )
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    describe "InstanceMethods" do

      describe "#initialize" do
        it "Should be able to initialize with valid credentials" do
          client1 = JenkinsApi::Client.new(
            YAML.load_file(File.expand_path(@creds_file, __FILE__))
          )
          expect(client1.class).to eq JenkinsApi::Client
        end

        it "Should accept a YAML argument when creating a new client" do
          client3 = JenkinsApi::Client.new(
            YAML.load_file(File.expand_path(@creds_file, __FILE__))
          )
          expect(client3.class).to eq JenkinsApi::Client
        end

        it "Should fail if wrong credentials are given" do
          client2 = JenkinsApi::Client.new(
            :server_ip => @server_ip,
            :username => 'stranger',
            :password => 'hacked',
            :log_location => '/dev/null'
          )
          expect{ client2.job.list_all }.to raise_error(JenkinsApi::Exceptions::Unauthorized)
        end
      end
      describe "#get_jenkins_version" do
        it "Should the jenkins version" do
          expect(@client.get_jenkins_version.class).to eq String
        end
      end

      describe "#get_hudson_version" do
        it "Should get the hudson version" do
          expect(@client.get_hudson_version.class).to eq String
        end
      end

      describe "#exec_script" do
        it "Should execute the provided groovy script" do
          expect(@client.exec_script('println("hi")')).to eq "hi\n"
        end
      end
    end

    describe "SubClassAccessorMethods" do
      describe "#job" do
        it "Should return a job object on call" do
          expect(@client.job.class).to eq JenkinsApi::Client::Job
        end
      end

      describe "#node" do
        it "Should return a node object on call" do
          expect(@client.node.class).to eq JenkinsApi::Client::Node
        end
      end

      describe "#view" do
        it "Should return a view object on call" do
          expect(@client.view.class).to eq JenkinsApi::Client::View
        end
      end

      describe "#system" do
        it "Should return a system object on call" do
          expect(@client.system.class).to eq JenkinsApi::Client::System
        end
      end

      describe "#queue" do
        it "Should return a build queue object on call" do
          expect(@client.queue.class).to eq JenkinsApi::Client::BuildQueue
        end
      end
    end

  end

  context "Given a server with a self-signed SSL certificate" do
    let(:creds_file) { '~/.jenkins_api_client/spec.yml' }
    let(:creds) {
      creds = YAML.load_file(File.expand_path(creds_file, __FILE__))
      creds[:server_port] = 8443
      creds[:ssl] = true
      creds
    }
    let(:client) { JenkinsApi::Client.new(creds) }

    it "Should abort the connection with an SSL error" do
      expect {
        client.job.list_all
      }.to raise_error(OpenSSL::SSL::SSLError, /certificate verify failed/)
    end

    context "Given a client configured to trust the server's certificate" do
      before do
        creds[:ca_file] = File.expand_path('~/.jenkins_api_client/server.cert.pem', __FILE__)
      end

      it "Should connect without an error" do
        client.job.list_all
      end
    end
  end
end
