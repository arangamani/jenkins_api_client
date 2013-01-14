require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::Job do
  context "With properly initialized Client and all methods defined" do

    before do
      @client = mock
      @job = JenkinsApi::Client::Job.new(@client)
    end

    it "Should have #create_job method and should accept #job_name and xml" do
      job_name = 'test_job'
      xml = '<name>somename</name>'
      @client.should_receive(:post_config)
      @job.create(job_name, xml)
    end

    it "Should have #create_freestyle method and should accept a hash" do
      params = {:name => 'test_job'}
      @client.should_receive(:post_config)
      @job.create_freestyle(params)
    end

    it "Should have #delete method and should accept the job name" do
      @client.should_receive(:api_post_request)
      @job.delete('test_job')
    end

    it "Should have #stop_build method and should accept the job name and build number" do
      @client.should_receive(:api_get_request).twice.and_return("building" => true, "nextBuildNumber" => 2)
      @client.should_receive(:api_post_request)
      @job.stop_build('test_job')
    end

  end
end
