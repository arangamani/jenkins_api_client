#
# Specifying JenkinsApi::Client::Job class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::Job do
  context "With properly initialized client" do
    before(:all) do
      @helper = JenkinsApiSpecHelper::Helper.new
      @creds_file = '~/.jenkins_api_client/login.yml'
      @job_name_prefix = 'awesome_rspec_test_job'
      @filter = "^#{@job_name_prefix}.*"
      @job_name = ''
      begin
        @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(@creds_file, __FILE__)))
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
      # Creating 10 jobs to run the spec tests on
      begin
        10.times do |num|
          xml = @helper.create_job_xml
          job = "#{@job_name_prefix}_#{num}"
          @job_name = job if num == 0
          @client.job.create(job, xml).to_i.should == 200
        end
      rescue Exception => e
        puts "WARNING: Can't create jobs for preparing to spec tests"
      end
    end

    it "Should be able to create a job" do
      xml = @helper.create_job_xml
      @client.job.create("some_random_nonexistent_job", xml).to_i.should == 200
    end

    it "Should be able to re-create a job" do
      @client.job.recreate("some_random_nonexistent_job").to_i.should == 200
    end

    it "Should be able to change the description of a job" do
      @client.job.change_description("some_random_nonexistent_job", "The description has been changed by the spec test").to_i.should == 200
    end

    it "Should be able to delete a job" do
      @client.job.delete("some_random_nonexistent_job").to_i.should == 302
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

    it "Should be able to list jobs by status" do
      names = @client.job.list('success')
      names.class.should == Array
      names.each do |name|
        status = @client.job.get_current_build_status(name)
        status.should == 'success'
      end
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
      @client.job.get_upstream_projects(@job_name).class.should == Array
    end

    it "Should list downstream projects of the specified job" do
      @client.job.get_downstream_projects(@job_name).class.should == Array
    end

    it "Should get builds of a specified job" do
      @client.job.get_builds(@job_name).class.should == Array
    end

    it "Should obtain the current build status for the specified job" do
      build_status = @client.job.get_current_build_status(@job_name)
      build_status.class.should == String
      valid_build_status = ["not_run", "aborted", "success", "failure", "unstable", "running"]
      valid_build_status.include?(build_status).should be_true
    end

    it "Should list all running jobs" do
      @client.job.list_running.class.should == Array
    end

    it "Should build the specified job" do
      @client.job.get_current_build_status(@job_name).should_not == "running"
      response = @client.job.build(@job_name)
      response.to_i.should == 302
      # Sleep for 20 seconds so we don't hit the Jenkins quiet period
      sleep 20
      @client.job.get_current_build_status(@job_name).should == "running"
      while @client.job.get_current_build_status(@job_name) == "running" do
        # Waiting for this job to finish so it doesn't affect other tests
        sleep 10
      end
    end

#    it "Should be able to abort a recent build of a running job" do
#      @client.job.get_current_build_status(@job_name).should_not == "running"
#      @client.job.build(@job_name)
#      sleep 20
#      @client.job.get_current_build_status(@job_name).should == "running"
#      sleep 20
#      @client.job.stop_build(@job_name).should == 302
#      sleep 20
#      @client.job.get_current_build_status(@job_name).should == "aborted"
#    end

    it "Should be able to restrict a job to a node" do
      @client.job.restrict_to_node(@job_name, 'master').to_i.should == 200
      # Run it again to make sure that the replace existing node works
      @client.job.restrict_to_node(@job_name, 'master').to_i.should == 200
    end

    it "Should be able to chain jobs" do
      #
      jobs = @client.job.list(@filter)
      jobs.class.should == Array
      start_jobs = @client.job.chain(jobs, 'success', ["all"])
      start_jobs.class.should == Array
      start_jobs.length.should == 1

      start_jobs = @client.job.chain(jobs, 'failure', ["not_run", "aborted", 'failure'], 3)
      start_jobs.class.should == Array
      start_jobs.length.should == 3
    end

    after(:all) do
      job_names = @client.job.list(@filter)
      job_names.each { |job_name|
        @client.job.delete(job_name)
      }
    end

  end
end
