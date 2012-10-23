require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::Job do
  context "With properly initialized client" do
    before(:all) do
      @creds_file = '~/.jenkins_api_client/login.yml'
      @filter = '^test_aws_est_cenhvm.*'
      begin
        @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
    end

    it "Should list all jobs" do
      @client.job.list_all.class.should == Array
    end

    it "Should return job names based on the filter" do
      names = @client.job.list(@filter)
      names.class.should == Array
      names.each { |name|
        name.should match /#{@filter}/i
      }
    end

    it "Should return all job names with details" do
      @client.job.list_all_with_details.class.should == Array
    end

    it "Should list details of a particular job" do
      job_name = @client.job.list(@filter)[0]
      job_name.class.should == String
      @client.job.list_details(job_name).class.should == Hash
    end

    it "Should list upstream projects of the specified job" do
      job_name = @client.job.list(@filter)[0]
      job_name.class.should == String
      @client.job.get_upstream_projects(job_name).class.should == Array
    end

    it "Should list downstream projects of the specified job" do
      job_name = @client.job.list(@filter)[0]
      job_name.class.should == String
      @client.job.get_downstream_projects(job_name).class.should == Array
    end

    it "Should get builds of a specified job" do
      job_name = @client.job.list(@filter)[0]
      job_name.class.should == String
      @client.job.get_builds(job_name).class.should == Array
    end

    it "Should obtain the current build status for the specified job" do
      job_name = @client.job.list(@filter)[0]
      job_name.class.should == String
      build_status = @client.job.get_current_build_status(job_name)
      build_status.class.should == String
      valid_build_status = ["not run", "aborted", "success", "failure", "unstable", "running"]
      valid_build_status.include?(build_status).should be_true
    end

#    it "Should list all running jobs" do
#      @client.job.list_running.class.should == Array
#    end

    it "Should build the specified job" do
      job_name = @client.job.list(@filter)[0]
      job_name.class.should == String
      @client.job.get_current_build_status(job_name).should_not == "running"
      response = @client.job.build(job_name)
      response.to_i.should == 302
      sleep 2
#      @client.job.get_current_build_status(job_name).should == "running"
    end

  end
end
