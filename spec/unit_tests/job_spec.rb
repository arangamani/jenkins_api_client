require File.expand_path('../spec_helper', __FILE__)
require 'net/http'

describe JenkinsApi::Client::Job do
  context "With properly initialized Client and all methods defined" do

    before do
      @client = mock
      @job = JenkinsApi::Client::Job.new(@client)
      @sample_json_response = {
        "jobs" => [
          {"name" => "test_job"},
          {"name" => "test_job2"}
        ]
      }
      @sample_json_job_response = {
        "downstreamProjects" => ["test_job1"],
        "upstreamProjects" => ["test_job2"],
        "builds" => [],
        "color" => "running",
        "nextBuildNumber" => 2
      }
      @sample_job_xml = File.read(
        File.expand_path('../fixtures/files/job_sample.xml', __FILE__))
    end

    describe "InstanceMethods" do

      describe "#create_job" do
        it "accepts job_name and xml and creates the job" do
          job_name = 'test_job'
          xml = '<name>somename</name>'
          @client.should_receive(:post_config)
          @job.create(job_name, xml)
        end
      end

      describe "#create_freestyle" do
        it "creates a simple freestyle job" do
          params = {
            :name => 'test_job_using_params'
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "creates a freestyle job with shell command" do
          params = {
            :name => "test_job_using_params_shell",
            :shell_command => "echo this is a freestyle project"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts Git SCM provider" do
          params = {
            :name => "test_job_using_params_git",
            :scm_provider => "git",
            :scm_url => "git://github.com/arangamani/jenkins_api_client/git",
            :scm_branch => "master"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts subversion SCM provider" do
          params = {
            :name => "test_job_using_params_subversion",
            :scm_provider => "subversion",
            :scm_url => "http://svn.freebsd.org/base",
            :scm_branch => "master"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts CVS SCM provider with branch" do
          params = {
            :name => "test_job_using_params_cvs_branch",
            :scm_provider => "cvs",
            :scm_url => "http://cvs.NetBSD.org",
            :scm_module => "src",
            :scm_branch => "MAIN"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts CVS SCM provider with tag" do
          params = {
            :name => "test_job_using_params_cvs_tag",
            :scm_provider => "cvs",
            :scm_url => "http://cvs.NetBSD.org",
            :scm_module => "src",
            :scm_tag => "MAIN"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts timer and creates job" do
          params = {
            :name => "test_job_with_timer",
            :timer => "* * * * *"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts individual targets for skype notification" do
          params = {
            :name => "test_job_with_individual_skype_target",
            :skype_targets => "testuser"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts group targets for skype notification" do
          params = {
            :name => "test_job_with_group_skype_target",
            :skype_targets => "*testgroup"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
        it "accepts complex configuration for skype notifications" do
          params = {
            :name => "test_job_with_complex_skype_configuration",
            :skype_targets => "testuser *testgroup anotheruser *anothergroup",
            :skype_strategy => "failure_and_fixed",
            :skype_notify_on_build_start => true,
            :skype_notify_suspects => true,
            :skype_notify_culprits => true,
            :skype_notify_fixers => true,
            :skype_notify_upstream_committers => false,
            :skype_message => "summary_and_scm_changes"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
      end

      describe "#copy" do
        it "accepts the from and to job names and copies the from job to the to job" do
          @client.should_receive(:api_post_request).with(
            "/createItem?name=new_job&mode=copy&from=old_job"
          )
          @job.copy("old_job", "new_job")
        end
        it "accepts the from job name and copies the from job to the copy_of_from job" do
          @client.should_receive(:api_post_request).with(
            "/createItem?name=copy_of_old_job&mode=copy&from=old_job"
          )
          @job.copy("old_job")
        end
      end

      describe "#add_email_notification" do
        it "accepts email address and adds to existing job" do
          params = {
            :name => "email_notification_test_job"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
          @client.should_receive(:get_config).and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.add_email_notification(
            :name => "email_notification_test_job",
            :notification_email => "testuser@testdomain.com"
          )
        end
      end

      describe "#add_skype_notification" do
        it "accepts skype configuration and adds to existing job" do
          params = {
            :name => "skype_notification_test_job"
          }
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
          @client.should_receive(:get_config).and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.add_skype_notification(
            :name => "skype_notification_test_job",
            :skype_targets => "testuser"
          )
        end
      end

      describe "#rename" do
        it "accepts the old and new job names and renames the job" do
          @client.should_receive(:api_post_request).with(
            "/job/old_job/doRename?newName=new_job"
          )
          @job.rename("old_job", "new_job")
        end
      end

      describe "#delete" do
        it "accepts the job name and deletes the job" do
          @client.should_receive(:api_post_request)
          @job.delete('test_job')
        end
      end

      describe "#wipe_out_workspace" do
        it "accepts the job name and wipes out the workspace of the job" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/doWipeOutWorkspace"
          )
          @job.wipe_out_workspace('test_job')
        end
      end

      describe "#stop_build" do
        it "accepts the job name and build number and stops the build" do
          @client.should_receive(:api_get_request).twice.and_return(
            "building" => true, "nextBuildNumber" => 2)
          @client.should_receive(:api_post_request)
          @job.stop_build('test_job')
        end
      end

      describe "#get_console_output" do
        it "accepts the job name and the obtains the console output" do
          msg = "/job/test_job/1/logText/progressiveText?start=0"
          @client.should_receive(:api_get_request).
                  with(msg, nil, nil, true).
                  and_return(Net::HTTP.get_response(URI('http://example.com/index.html')))
          @job.get_console_output('test_job', 1, 0, 'text')
        end

        it "raises an error if invalid mode is specified" do
          expect(
            lambda do
              @job.get_console_output('test_job', 1, 0, 'image')
            end
          ).to raise_error
        end
      end

      describe "#list_all" do
        it "accepts no parameters and returns all jobs in an array" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_response)
          response = @job.list_all
          response.class.should == Array
          response.size.should == @sample_json_response["jobs"].size
        end
      end

      describe "#exists?" do
        it "accepts a job name and returns true if the job exists" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_response)
          @job.exists?("test_job").should == true
        end
      end

      describe "#list_by_status" do
        it "accepts the status and returns jobs in specified status" do
          @client.should_receive(:api_get_request).twice.and_return(
            @sample_json_response)
          @job.list_by_status("success").class.should == Array
        end
        it "accepts the status and returns the jobs in specified status" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_response)
          @job.list_by_status("success", ["test_job"]).class.should == Array
        end
      end

      describe "#list" do
        it "accepts a filter and returns all jobs matching the filter" do
          @client.should_receive(:api_get_request).and_return(
            "jobs" => ["test_job"])
          @job.list("filter").class.should == Array
        end
      end

      describe "#list_all_with_details" do
        it "accepts no parameters and returns all jobs with details" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_response)
          response = @job.list_all_with_details
          response.class.should == Array
          response.size.should == @sample_json_response["jobs"].size
        end
      end

      describe "#list_details" do
        it "accepts the job name and returns its details" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_response)
          response = @job.list_details("test_job")
          response.class.should == Hash
        end
      end

      describe "#get_upstream_projects" do
        it "accepts the job name and returns its upstream projects" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_job_response)
          response = @job.get_upstream_projects("test_job")
          response.class.should == Array
        end
      end

      describe "#get_downstream_projects" do
        it "accepts the job name and returns its downstream projects" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_job_response)
          response = @job.get_downstream_projects("test_job")
          response.class.should == Array
        end
      end

      describe "#get_builds" do
        it "accepts the job name and returns its builds" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_job_response)
          response = @job.get_builds("test_job")
          response.class.should == Array
        end
      end

      describe "#color_to_status" do
        it "accepts the color and convert it to correct status" do
          @job.color_to_status("blue").should         == "success"
          @job.color_to_status("blue_anime").should   == "running"
          @job.color_to_status("red").should          == "failure"
          @job.color_to_status("red_anime").should    == "running"
          @job.color_to_status("yellow").should       == "unstable"
          @job.color_to_status("yellow_anime").should == "running"
          @job.color_to_status("grey").should         == "not_run"
          @job.color_to_status("grey_anime").should   == "running"
          @job.color_to_status("aborted").should      == "aborted"
        end
        it "returns invalid as the output if unknown color is detected" do
          @job.color_to_status("orange").should == "invalid"
        end
      end

      describe "#get_current_build_status" do
        it "accepts the job name and returns its current build status" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_job_response)
          @job.get_current_build_status("test_job").class.should == String
        end
      end

      describe "#get_current_build_number" do
        it "accepts the job name and returns its current build number" do
          @client.should_receive(:api_get_request).and_return(
            @sample_json_job_response)
          @job.get_current_build_number("test_job").class.should == Fixnum
        end
      end

      describe "#build" do
        it "accepts the job name and builds the job" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build").and_return(302)
          @job.build("test_job").should == 302
        end
        it "accepts the job name with params and builds the job" do
          @client.should_receive(:api_post_request).with(
              "/job/test_job/buildWithParameters",{:branch => 'feature/new-stuff'}).and_return(302)
          @job.build("test_job",{:branch => 'feature/new-stuff'}).should == 302
        end
      end

      describe "#enable" do
        it "accepts the job name and enables the job" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/enable").and_return(302)
          @job.enable("test_job").should == 302
        end
      end

      describe "#disable" do
        it "accepts the job name and disables the job" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/disable").and_return(302)
          @job.disable("test_job").should == 302
        end
      end

      describe "#get_config" do
        it "accepts the job name and obtains its config.xml" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return("<job>test_job</job>")
          @job.get_config("test_job").should == "<job>test_job</job>"
        end
      end

      describe "#post_config" do
        it "accepts the job name and posts its config.xml to the server" do
          @client.should_receive(:post_config).with(
            "/job/test_job/config.xml", "<job>test_job</job>")
          @job.post_config("test_job", "<job>test_job</job>")
        end
      end

      describe "#change_description" do
        it "accepts the job name and description and changes it" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.change_description("test_job", "new description")
        end
      end

      describe "#block_build_when_downstream_building" do
        it "accepts the job name and blocks build when downstream builds" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.block_build_when_downstream_building("test_job")
        end
      end

      describe "#unblock_build_when_downstream_building" do
        it "accepts the job name and unblocks build when downstream builds" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @job.unblock_build_when_downstream_building("test_job")
        end
      end

      describe "#block_build_when_upstream_building" do
        it "accepts the job name and blocks build when upstream is building" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.block_build_when_upstream_building("test_job")
        end
      end

      describe "#unblock_build_when_upstream_building" do
        it "accepts the job name and unblocks build when upstream builds" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @job.unblock_build_when_upstream_building("test_job")
        end
      end

      describe "#execute_concurrent_builds" do
        it "accepts the job name and option and executes concurrent builds" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.execute_concurrent_builds("test_job", true)
        end
      end

      describe "#restrict_to_node" do
        it "accepts the job name and node name and restricts the job node" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.restrict_to_node("test_job", "test_slave")
        end
      end

      describe "#unchain" do
        it "accepts the job names and unchains them" do
          @client.should_receive(:debug).and_return(false)
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.unchain(["test_job"])
        end
      end

      describe "#chain" do
        it "accepts the job names and other options and chains them" do
          @client.should_receive(:debug).and_return(false)
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.unchain(["test_job"])
        end
      end

    end
  end
end
