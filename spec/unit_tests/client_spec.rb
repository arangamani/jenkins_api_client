require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client do
  context "With valid credentials given" do
    before do
    end

    it "Should be able to initialize without exception" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            server_ip: '127.0.0.1',
            server_port: 8080,
            username: 'username',
            password: 'password'
          })
        end
      ).not_to raise_error
    end

    it "Should be able to get a Client::Job object by calling the job method" do
      client = JenkinsApi::Client.new({
                                        server_ip: '127.0.0.1',
                                        server_port: 8080,
                                        username: 'username',
                                        password: 'password'
                                      })
      client.job.class.should == JenkinsApi::Client::Job
    end

    it "Should be able to get a Client::Node object by calling the node method" do
      client = JenkinsApi::Client.new({
                                        server_ip: '127.0.0.1',
                                        server_port: 8080,
                                        username: 'username',
                                        password: 'password'
                                      })
      client.node.class.should == JenkinsApi::Client::Node
    end

    it "Should be able to get a Client::View object by calling the view method" do
      client = JenkinsApi::Client.new({
                                        server_ip: '127.0.0.1',
                                        server_port: 8080,
                                        username: 'username',
                                        password: 'password'
                                      })
      client.view.class.should == JenkinsApi::Client::View
    end

    it "Should be able to get a Client::System object by calling the system method" do
      client = JenkinsApi::Client.new({
                                        server_ip: '127.0.0.1',
                                        server_port: 8080,
                                        username: 'username',
                                        password: 'password'
                                      })
      client.system.class.should == JenkinsApi::Client::System
    end

  end

  context "With some required parameters" do

    it "Should fail if server_ip is missing" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            bogus: '127.0.0.1',
            server_port: 8080,
            username: 'username',
            password: 'password'
          })
        end
      ).to raise_error
    end

    it "Should fail if username is missing" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            server_ip: '127.0.0.1',
            server_port: 8080,
            bogus: 'username',
            password: 'password'
          })
        end
      ).to raise_error
    end

    it "Should fail if password is missing" do
      expect(
        lambda do
          JenkinsApi::Client.new({
            server_ip: '127.0.0.1',
            server_port: 8080,
            username: 'username',
            bogus: 'password'
          })
        end
      ).to raise_error
    end

  end
end
