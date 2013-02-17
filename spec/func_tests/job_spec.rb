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
      @creds_file = '~/.jenkins_api_client/spec.yml'
      @job_name_prefix = 'awesome_rspec_test_job'
      @filter = "^#{@job_name_prefix}.*"
      @job_name = ''
      begin
        @client = JenkinsApi::Client.new(
          YAML.load_file(File.expand_path(@creds_file, __FILE__))
        )
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

    describe "InstanceMethods" do

      describe "#initialize" do
        it "Initializes without any exception" do
          expect(
            lambda { job = JenkinsApi::Client::Job.new(@client) }
          ).not_to raise_error
        end
        it "Raises an error if a reference of client is not passed" do
          expect(
            lambda { job = JenkinsApi::Client::Job.new() }
          ).to raise_error
        end
      end

      describe "#create" do
        it "Should be able to create a job by getting an xml" do
          xml = @helper.create_job_xml
          name = "qwerty_nonexistent_job"
          @client.job.create(name, xml).to_i.should == 200
          @client.job.list(name).include?(name).should be_true
        end
      end

      describe "#create_freestyle" do

        def test_and_validate(name, params)
          @client.job.create_freestyle(params).to_i.should == 200
          @client.job.list(name).include?(name).should be_true
          @client.job.delete(name).to_i.should == 302
          @client.job.list(name).include?(name).should be_false
        end

        it "Should be able to create a simple freestyle job" do
          name = "test_job_name_using_params"
          params = {
            :name => name
          }
          test_and_validate(name, params)
        end
        it "Should be able to create a freestyle job with shell command" do
          name = "test_job_using_params_shell"
          params = {
            :name => name,
            :shell_command => "echo this is a free style project"
          }
          test_and_validate(name, params)
        end
        it "Should accept Git SCM provider" do
          name = "test_job_with_git_scm"
          params = {
            :name => name,
            :scm_provider => "git",
            :scm_url => "git://github.com./arangamani/jenkins_api_client.git",
            :scm_branch => "master"
          }
          test_and_validate(name, params)
        end
        it "Should accept subversion SCM provider" do
          name = "test_job_with_subversion_scm"
          params = {
            :name => name,
            :scm_provider => "subversion",
            :scm_url => "http://svn.freebsd.org/base/",
            :scm_branch => "master"
          }
          test_and_validate(name, params)
        end
        it "Should accept CVS SCM provider with branch" do
          name = "test_job_with_cvs_scm_branch"
          params = {
            :name => name,
            :scm_provider => "cvs",
            :scm_url => "http://cvs.NetBSD.org",
            :scm_module => "src",
            :scm_branch => "MAIN"
          }
          test_and_validate(name, params)
        end
        it "Should accept CVS SCM provider with tag" do
          name = "test_job_with_cvs_scm_tag"
          params = {
            :name => name,
            :scm_provider => "cvs",
            :scm_url => "http://cvs.NetBSD.org",
            :scm_module => "src",
            :scm_tag => "MAIN"
          }
          test_and_validate(name, params)
        end
        it "Should fail if unsupported SCM is specified" do
          name = "test_job_unsupported_scm"
          params = {
            :name => name,
            :scm_provider => "non-existent",
            :scm_url => "http://non-existent.com/non-existent.non",
            :scm_branch => "master"
          }
          expect(
            lambda{ @client.job.create_freestyle(params) }
          ).to raise_error
        end
        it "Should accept restricted_node option" do
          name = "test_job_restricted_node"
          params = {
            :name => name,
            :restricted_node => "master"
          }
          test_and_validate(name, params)
        end
        it "Should accept block_build_when_downstream_building option" do
          name = "test_job_block_build_when_downstream_building"
          params = {
            :name => name,
            :block_build_when_downstream_building => true,
          }
          test_and_validate(name, params)
        end
        it "Should accept block_build_when_upstream_building option" do
          name = "test_job_block_build_when_upstream_building"
          params = {
            :name => name,
            :block_build_when_upstream_building => true
          }
          test_and_validate(name, params)
        end
        it "Should accept concurrent_build option" do
          name = "test_job_concurrent_build"
          params = {
            :name => name,
            :concurrent_build => true
          }
          test_and_validate(name, params)
        end
        it "Should accept the timer option" do
          name = "test_job_using_timer"
          params = {
            :name => name,
            :timer => "* * * * *"
          }
          test_and_validate(name, params)
        end
        it "Should accept child projects option" do
          name = "test_job_child_projects"
          params = {
            :name => name,
            :child_projects => @job_name,
            :child_threshold => "success"
          }
          test_and_validate(name, params)
        end
        it "Should accept notification_email option" do
          name = "test_job_notification_email"
          params = {
            :name => name,
            :notification_email => "kannan@testdomain.com"
          }
          test_and_validate(name, params)
        end
        it "Should accept notification for individual skype targets" do
          name = "test_job_with_individual_skype_targets"
          params = {
            :name => name,
            :skype_targets => "testuser"
          }
          test_and_validate(name, params)
        end
        it "Should accept notification for group skype targets" do
          name = "test_job_with_group_skype_targets"
          params = {
            :name => name,
            :skype_targets => "*testgroup"
          }
          test_and_validate(name, params)
        end
        it "Should accept complex skype configuration" do
          name = "test_job_with_complex_skype_configuration"
          params = {
            :name => name,
            :skype_targets => "testuser *testgroup anotheruser *anothergroup",
            :skype_strategy => "failure_and_fixed",
            :skype_notify_on_build_start => true,
            :skype_notify_suspects => true,
            :skype_notify_culprits => true,
            :skype_notify_fixers => true,
            :skype_notify_upstream_committers => false,
            :skype_message => "summary_and_scm_changes"
          }
          test_and_validate(name, params)
        end
      end

      describe "#add_skype_notification" do
        it "Should accept skype configuration and add to existing job" do
          name = "skype_notification_test_job"
          params = {
            :name => name
          }
          @client.job.create_freestyle(params).to_i.should == 200
          @client.job.add_skype_notification(
            :name => name,
            :skype_targets => "testuser"
          ).to_i.should == 200
          @client.job.delete(name).to_i.should == 302
        end
      end

      describe "#rename" do
        it "Should accept new and old job names and rename the job" do
          xml = @helper.create_job_xml
          @client.job.create("old_job_rename_test", xml)
          @client.job.rename("old_job_rename_test", "new_job_rename_test")
          @client.job.list("old_job_rename_test").should == []
          resp = @client.job.list("new_job_rename_test")
          resp.size.should == 1
          resp.first.should == "new_job_rename_test"
          @client.job.delete("new_job_rename_test")
        end
      end

      describe "#recreate" do
        it "Should be able to re-create a job" do
          @client.job.recreate("qwerty_nonexistent_job").to_i.should == 200
        end
      end

      describe "#change_description" do
        it "Should be able to change the description of a job" do
          @client.job.change_description("qwerty_nonexistent_job",
            "The description has been changed by the spec test"
          ).to_i.should == 200
        end
      end

      describe "#delete" do
        it "Should be able to delete a job" do
          @client.job.delete("qwerty_nonexistent_job").to_i.should == 302
        end
      end

      describe "#list_all" do
        it "Should list all jobs" do
          @client.job.list_all.class.should == Array
        end
      end

      describe "#list" do
        it "Should return job names based on the filter" do
          names = @client.job.list(@filter)
          names.class.should == Array
          names.each { |name|
            name.should match /#{@filter}/i
          }
        end
      end

      describe "#list_by_status" do
        it "Should be able to list jobs by status" do
          names = @client.job.list_by_status('success')
          names.class.should == Array
          names.each do |name|
            status = @client.job.get_current_build_status(name)
            status.should == 'success'
          end
        end
      end

      describe "#list_all_with_details" do
        it "Should return all job names with details" do
          @client.job.list_all_with_details.class.should == Array
        end
      end

      describe "#list_details" do
        it "Should list details of a particular job" do
          job_name = @client.job.list(@filter)[0]
          job_name.class.should == String
          @client.job.list_details(job_name).class.should == Hash
        end
      end

      describe "#get_upstream_projects" do
        it "Should list upstream projects of the specified job" do
          @client.job.get_upstream_projects(@job_name).class.should == Array
        end
      end

      describe "#get_downstream_projects" do
        it "Should list downstream projects of the specified job" do
          @client.job.get_downstream_projects(@job_name).class.should == Array
        end
      end

      describe "#get_builds" do
        it "Should get builds of a specified job" do
          @client.job.get_builds(@job_name).class.should == Array
        end
      end

      describe "#get_current_build_status" do
        it "Should obtain the current build status for the specified job" do
          build_status = @client.job.get_current_build_status(@job_name)
          build_status.class.should == String
          valid_build_status = [
            "not_run",
            "aborted",
            "success",
            "failure",
            "unstable",
            "running"
          ]
          valid_build_status.include?(build_status).should be_true
        end
      end

      describe "#build" do
        it "Should build the specified job" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"
          response = @client.job.build(@job_name)
          response.to_i.should == 302
          # Sleep for 6 seconds so we don't hit the Jenkins quiet period (5
          # seconds)
          sleep 6
          @client.job.get_current_build_status(@job_name).should == "running"
          while @client.job.get_current_build_status(@job_name) == "running" do
            # Waiting for this job to finish so it doesn't affect other tests
            sleep 10
          end
        end
      end

      describe "#stop" do
        it "Should be able to abort a recent build of a running job" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"
          @client.job.build(@job_name)
          sleep 6
          @client.job.get_current_build_status(@job_name).should == "running"
          sleep 5
          @client.job.stop_build(@job_name).to_i.should == 302
          sleep 5
          @client.job.get_current_build_status(@job_name).should == "aborted"
        end
      end

      describe "#restrict_to_node" do
        it "Should be able to restrict a job to a node" do
          @client.job.restrict_to_node(@job_name, 'master').to_i.should == 200
          # Run it again to make sure that the replace existing node works
          @client.job.restrict_to_node(@job_name, 'master').to_i.should == 200
        end
      end

      describe "#chain" do
        it "Should be able to chain all jobs" do
          # Filter jobs to be chained
          jobs = @client.job.list(@filter)
          jobs.class.should == Array
          start_jobs = @client.job.chain(jobs, 'success', ["all"])
          start_jobs.class.should == Array
          start_jobs.length.should == 1
        end
        it "Should be able to chain jobs based on the specified criteria" do
          jobs = @client.job.list(@filter)
          jobs.class.should == Array
          start_jobs = @client.job.chain(
            jobs,
            'failure',
            ["not_run", "aborted", 'failure'],
            3
          )
          start_jobs.class.should == Array
          start_jobs.length.should == 3
        end
      end

    end

    after(:all) do
      job_names = @client.job.list(@filter)
      job_names.each { |job_name|
        @client.job.delete(job_name)
      }
    end

  end
end
