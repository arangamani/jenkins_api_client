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
      @creds = YAML.load_file(File.expand_path(@creds_file, __FILE__))
      @job_name_prefix = 'awesome_rspec_test_job'
      @filter = "^#{@job_name_prefix}.*"
      @job_name = ''
      @valid_post_responses = [200, 201, 302]
      begin
        @client = JenkinsApi::Client.new(@creds)
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
          @valid_post_responses.should include(
            @client.job.create(name, xml).to_i
          )
          @client.job.list(name).include?(name).should be_true
        end
        it "Should raise proper exception when the job already exists" do
          xml = @helper.create_job_xml
          name = "the_duplicate_job"
          @valid_post_responses.should include(
            @client.job.create(name, xml).to_i
          )
          @client.job.list(name).include?(name).should be_true
          expect(
            lambda { @client.job.create(name, xml) }
          ).to raise_error(JenkinsApi::Exceptions::JobAlreadyExists)
          @valid_post_responses.should include(
            @client.job.delete(name).to_i
          )
        end
      end

      describe "#create_freestyle" do

        def test_and_validate(name, params, config_line = nil)
          @valid_post_responses.should include(
            @client.job.create_freestyle(params).to_i
          )
          @client.job.list(name).include?(name).should be_true
          # Test for the existense of the given line in the config.xml of the
          # job created
          unless config_line.nil?
            config = @client.job.get_config(name)
            config.should =~ /#{config_line}/
          end
          @valid_post_responses.should include(
            @client.job.delete(name).to_i
          )
          @client.job.list(name).include?(name).should be_false
        end

        it "Should create a freestyle job with just name" do
          name = "test_job_name_using_params"
          params = {
            :name => name
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with shell command" do
          name = "test_job_using_params_shell"
          params = {
            :name => name,
            :shell_command => "echo this is a free style project"
          }
          test_and_validate(
            name,
            params,
            "<command>echo this is a free style project</command>"
          )
        end
        it "Should create a freestyle job with Git SCM provider" do
          name = "test_job_with_git_scm"
          params = {
            :name => name,
            :scm_provider => "git",
            :scm_url => "git://github.com./arangamani/jenkins_api_client.git",
            :scm_branch => "master"
          }
          test_and_validate(
            name,
            params,
            "<url>git://github.com./arangamani/jenkins_api_client.git</url>"
          )
        end
        it "Should create a freestyle job with SVN SCM provider" do
          name = "test_job_with_subversion_scm"
          params = {
            :name => name,
            :scm_provider => "subversion",
            :scm_url => "http://svn.freebsd.org/base/",
            :scm_branch => "master"
          }
          test_and_validate(
            name,
            params,
            "<remote>http://svn.freebsd.org/base/</remote>"
          )
        end
        it "Should create a freestyle job with CVS SCM provider with branch" do
          name = "test_job_with_cvs_scm_branch"
          params = {
            :name => name,
            :scm_provider => "cvs",
            :scm_url => "http://cvs.NetBSD.org",
            :scm_module => "src",
            :scm_branch => "MAIN"
          }
          test_and_validate(
            name,
            params,
            "<cvsroot>http://cvs.NetBSD.org</cvsroot>"
          )
        end
        it "Should create a freestyle job with CVS SCM provider with tag" do
          name = "test_job_with_cvs_scm_tag"
          params = {
            :name => name,
            :scm_provider => "cvs",
            :scm_url => "http://cvs.NetBSD.org",
            :scm_module => "src",
            :scm_tag => "MAIN"
          }
          test_and_validate(
            name,
            params,
            "<cvsroot>http://cvs.NetBSD.org</cvsroot>"
          )
        end
        it "Should raise an error if unsupported SCM is specified" do
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
        it "Should create a freestyle job with restricted_node option" do
          name = "test_job_restricted_node"
          params = {
            :name => name,
            :restricted_node => "master"
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with" +
          " block_build_when_downstream_building option" do
          name = "test_job_block_build_when_downstream_building"
          params = {
            :name => name,
            :block_build_when_downstream_building => true,
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with" +
          " block_build_when_upstream_building option" do
          name = "test_job_block_build_when_upstream_building"
          params = {
            :name => name,
            :block_build_when_upstream_building => true
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with concurrent_build option" do
          name = "test_job_concurrent_build"
          params = {
            :name => name,
            :concurrent_build => true
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with timer option" do
          name = "test_job_using_timer"
          params = {
            :name => name,
            :timer => "* * * * *"
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with child projects option" do
          name = "test_job_child_projects"
          params = {
            :name => name,
            :child_projects => @job_name,
            :child_threshold => "success"
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with notification_email option" do
          name = "test_job_notification_email"
          params = {
            :name => name,
            :notification_email => "kannan@testdomain.com"
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with notification for" +
          " individual skype targets" do
          name = "test_job_with_individual_skype_targets"
          params = {
            :name => name,
            :skype_targets => "testuser"
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with notification for" +
          " group skype targets" do
          name = "test_job_with_group_skype_targets"
          params = {
            :name => name,
            :skype_targets => "*testgroup"
          }
          test_and_validate(name, params)
        end
        it "Should create a freestyle job with complex skype" +
          " configuration" do
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
        it "Should raise an error if the input parameters is not a Hash" do
          expect(
            lambda {
              @client.job.create_freestyle("a_string")
            }
          ).to raise_error(ArgumentError)
        end
        it "Should raise an error if the required name paremeter is missing" do
          expect(
            lambda {
              @client.job.create_freestyle(:shell_command => "sleep 60")
            }
          ).to raise_error(ArgumentError)
        end
      end

      describe "#copy" do
        it "accepts the from and to job name and copies the job" do
          xml = @helper.create_job_xml
          @client.job.create("from_job_copy_test", xml)
          @client.job.copy("from_job_copy_test", "to_job_copy_test")
          @client.job.list(".*_job_copy_test").should == [
            "from_job_copy_test", "to_job_copy_test"
          ]
          @client.job.delete("from_job_copy_test")
          @client.job.delete("to_job_copy_test")
        end
        it "accepts the from job name and copies the from job to the" +
          " copy_of_from job" do
          xml = @helper.create_job_xml
          @client.job.create("from_job_copy_test", xml)
          @client.job.copy("from_job_copy_test")
          @client.job.list(".*_job_copy_test").should == [
            "copy_of_from_job_copy_test", "from_job_copy_test"
          ]
          @client.job.delete("from_job_copy_test")
          @client.job.delete("copy_of_from_job_copy_test")
        end
      end

      describe "#add_email_notification" do
        it "Should accept email address and add to existing job" do
          name = "email_notification_test_job"
          params = {:name => name}
          @valid_post_responses.should include(
            @client.job.create_freestyle(params).to_i
          )
          @valid_post_responses.should include(
            @client.job.add_email_notification(
              :name => name,
              :notification_email => "testuser@testdomain.com"
            ).to_i
          )
          @valid_post_responses.should include(
            @client.job.delete(name).to_i
          )
        end
      end

      describe "#add_skype_notification" do
        it "Should accept skype configuration and add to existing job" do
          name = "skype_notification_test_job"
          params = {
            :name => name
          }
          @valid_post_responses.should include(
            @client.job.create_freestyle(params).to_i
          )
          @valid_post_responses.should include(
            @client.job.add_skype_notification(
              :name => name,
              :skype_targets => "testuser"
            ).to_i
          )
          @valid_post_responses.should include(
            @client.job.delete(name).to_i
          )
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
          @valid_post_responses.should include(
            @client.job.recreate("qwerty_nonexistent_job").to_i
          )
        end
      end

      describe "#change_description" do
        it "Should be able to change the description of a job" do
          @valid_post_responses.should include(
            @client.job.change_description("qwerty_nonexistent_job",
            "The description has been changed by the spec test").to_i
          )
        end
      end

      describe "#delete" do
        it "Should be able to delete a job" do
          @valid_post_responses.should include(
            @client.job.delete("qwerty_nonexistent_job").to_i
          )
        end
      end

      describe "#wipe_out_workspace" do
        it "Should be able to wipe out the workspace of a job" do
          xml = @helper.create_job_xml
          @client.job.create("wipeout_job_test", xml)
          @valid_post_responses.should include(
            @client.job.wipe_out_workspace("wipeout_job_test").to_i
          )
          @client.job.delete("wipeout_job_test")
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

      describe "#list_builds" do
        it "Should get builds of a specified job, and query their parameters" do
          job = 'dummy_with_params'
          begin
            tries ||= 1
            xml = @helper.create_job_with_params_xml
            @client.job.create(job, xml).to_i.should == 200
          rescue JenkinsApi::Exceptions::JobAlreadyExists
            @client.job.delete(job)
            tries -= 1
            retry if tries >= 0
          end

          2.times do |num|
            @client.job.build(job, {"PARAM1" => num})
            sleep 10
            while @client.job.get_current_build_status(job) == "running" do
              sleep 2
            end
          end
          builds = @client.job.list_builds(job)
          builds.class.should == Array
          builds.map {|b| b.id }.sort.should == [1, 2]
          builds.map {|b| b.params['PARAM1']}.sort.should == ['0', '1']
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

        def wait_for_job_to_finish(job_name)
          while @client.job.get_current_build_status(@job_name) == "running" do
            # Waiting for this job to finish so it doesn't affect other tests
            sleep 10
          end
        end

        it "Should build the specified job" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"
          response = @client.job.build(@job_name)
          # As of Jenkins version 1.519 the job build responds with a 201
          # status code.
          @valid_post_responses.should include(response.to_i)
          # Sleep for 10 seconds so we don't hit the Jenkins quiet period (5
          # seconds)
          sleep 10
          @client.job.get_current_build_status(@job_name).should == "running"
          wait_for_job_to_finish(@job_name)
        end

        it "Should build the specified job (wait for start)" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"
          expected_build_id = (@client.job.get_current_build_number(@job_name) || 0) + 1

          build_opts = {
            'build_start_timeout' => 10,
            'progress_proc' => lambda do |max_wait, curr_wait, poll_count|
              puts "Waited #{curr_wait}s of #{max_wait}s max - poll count = #{poll_count}"
            end,
            'completion_proc' => lambda do |build_number, cancelled|
              if build_number
                puts "Wait over: build #{build_number} started"
              else
                puts "Wait over: build not started, build #{cancelled ? "" : "NOT "} cancelled"
              end
            end
          }
          build_id = @client.job.build(@job_name, {}, build_opts)
          build_id.should_not be_nil
          build_id.should eql(expected_build_id)
          @client.job.get_current_build_status(@job_name).should == "running"
          wait_for_job_to_finish(@job_name)
        end

        # This build doesn't start in time, but we don't cancel it, so it will run if
        # Jenkins gets to it
        it "Should build the specified job (wait for start - but not long enough)" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"

          build_opts = {
            'build_start_timeout' => 1,
            'progress_proc' => lambda do |max_wait, curr_wait, poll_count|
              puts "Waited #{curr_wait}s of #{max_wait}s max - poll count = #{poll_count}"
            end,
            'completion_proc' => lambda do |build_number, cancelled|
              if build_number
                puts "Wait over: build #{build_number} started"
              else
                puts "Wait over: build not started, build #{cancelled ? "" : "NOT "}cancelled"
              end
            end
          }
          expect( lambda { @client.job.build(@job_name, {}, build_opts) } ).to raise_error(Timeout::Error)
          # Sleep for 10 seconds so we don't hit the Jenkins quiet period (5
          # seconds)
          sleep 10
          @client.job.get_current_build_status(@job_name).should == "running"
          wait_for_job_to_finish(@job_name)
        end

        # This build doesn't start in time, and we will attempt to cancel it so it
        # doesn't run
        it "Should build the specified job (wait for start - but not long enough, cancelled)" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"

          build_opts = {
            'build_start_timeout' => 1,
            'cancel_on_build_start_timeout' => true,
            'progress_proc' => lambda do |max_wait, curr_wait, poll_count|
              puts "Waited #{curr_wait}s of #{max_wait}s max - poll count = #{poll_count}"
            end,
            'completion_proc' => lambda do |build_number, cancelled|
              if build_number
                puts "Wait over: build #{build_number} started"
              else
                puts "Wait over: build not started, build #{cancelled ? "" : "NOT "}cancelled"
              end
            end
          }
          expect( lambda { @client.job.build(@job_name, {}, build_opts) } ).to raise_error(Timeout::Error)
        end
      end

      describe "#poll" do
        it "Should poll the specified job for scm changes" do
          response = @client.job.poll(@job_name)
          @valid_post_responses.should include(response.to_i)
        end
      end

      describe "#disable" do
        it "Should disable the specified job and then enable it again" do
          @client.job.list_details(@job_name)['buildable'].should == true
          response = @client.job.disable(@job_name)
          response.to_i.should == 302
          sleep 3
          @client.job.list_details(@job_name)['buildable'].should == false
          response = @client.job.enable(@job_name)
          response.to_i.should == 302
          sleep 3
          @client.job.list_details(@job_name)['buildable'].should == true
        end
      end

      describe "#stop" do
        it "Should be able to abort a recent build of a running job" do
          @client.job.get_current_build_status(
            @job_name
          ).should_not == "running"
          @client.job.build(@job_name)
          sleep 10
          @client.job.get_current_build_status(@job_name).should == "running"
          sleep 5
          @valid_post_responses.should include(
            @client.job.stop_build(@job_name).to_i
          )
          sleep 5
          @client.job.get_current_build_status(@job_name).should == "aborted"
        end
      end

      describe "#restrict_to_node" do
        it "Should be able to restrict a job to a node" do
          @valid_post_responses.should include(
            @client.job.restrict_to_node(@job_name, 'master').to_i
          )
          # Run it again to make sure that the replace existing node works
          @valid_post_responses.should include(
            @client.job.restrict_to_node(@job_name, 'master').to_i
          )
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
