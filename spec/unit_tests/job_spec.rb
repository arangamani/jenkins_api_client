require File.expand_path('../spec_helper', __FILE__)
require 'net/http'
require File.expand_path('../fake_http_response', __FILE__)

describe JenkinsApi::Client::Job do
  context "With properly initialized Client and all methods defined" do

    before do
      mock_logger = Logger.new "/dev/null"
      @client = JenkinsApi::Client.new({:server_ip => '127.0.0.1'})
      @client.should_receive(:logger).at_least(1).and_return(mock_logger)
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
      @sample_json_build_response = {
        "url" => "https://example.com/DEFAULT-VIEW/view/VIEW-NAME/job/test_job/2/",
        "artifacts" => [
          {
            "displayPath" => "output.json",
            "fileName" => "output.json",
            "relativePath" => "somepath/output.json"
          }
        ]
      }
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

      describe "#create_or_update" do
        it "creates jobs if they do not exist" do
            job_name = 'test_job'
            xml = '<name>somename</name>'

            mock_job_list_response = { "jobs" => [] } # job response w/ 0 jobs

            @client.should_receive(:api_get_request).with('').and_return(mock_job_list_response)
            @job.should_receive(:create).with(job_name, xml).and_return(nil)

            @job.create_or_update(job_name, xml)
        end

        it "updates existing jobs if they exist" do
            job_name = 'test_job'
            xml = '<name>somename</name>'

            mock_job_list_response = { "jobs" => [ { "name" => job_name } ] } # job response w/ 1 job

            @client.should_receive(:api_get_request).with('').and_return(mock_job_list_response)
            @job.should_receive(:update).with(job_name, xml).and_return(nil)

            @job.create_or_update(job_name, xml)
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
            :scm_branch => "master",
            :scm_credentials_id => 'foobar'
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
                  and_return(FakeResponse.new)
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
          @job.color_to_status("disabled").should     == "disabled"
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
        # First tests confirm the build method works the same as it used to
        it "accepts the job name and builds the job" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return(FakeResponse.new(302))
          @job.build("test_job").should == '302'
        end
        it "accepts the job name with params and builds the job" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/buildWithParameters",
            {:branch => 'feature/new-stuff'},
            true
          ).and_return(FakeResponse.new(302))
          @job.build("test_job", {:branch => 'feature/new-stuff'}).should == '302'
        end

        ### OLD NON-QUEUE RESPONSE JENKINS ###
        # Next tests confirm it deals with different jenkins versions and waits
        # for build to start (or not)
        context "accepts the job name and builds the job (w/timeout)" do
          before do
            @client.should_receive(:api_get_request).with(
              "/job/test_job").and_return({})
            @client.should_receive(:api_post_request).with(
              "/job/test_job/build", {}, true).and_return(FakeResponse.new(302))
            @client.should_receive(:api_get_request).with(
              "/job/test_job/1/").and_return({})
            @client.should_receive(:get_jenkins_version).and_return("1.1")
          end

          it "passes a number of seconds for timeout in opts={} parameter" do
            @job.build("test_job", {}, {'build_start_timeout' => 10}).should == 1
          end

          it "passes a true value for timeout in opts={} parameter" do
            @job.instance_variable_set :@client_timeout, 10
            @job.build("test_job", {}, true).should == 1
          end
        end

        it "accepts the job name and builds the job (with a false timeout value)" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return(FakeResponse.new(302))
          @job.build("test_job", {}, false).should == "302"
        end

        # wait for build to start (or not) (initial response will fail)
        it "accepts the job name and builds the job after short delay (w/timeout)" do
          @client.should_receive(:api_get_request).with(
            "/job/test_job").and_return({})
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return(FakeResponse.new(302))
          @client.should_receive(:api_get_request).with(
            "/job/test_job/1/").ordered.and_raise(JenkinsApi::Exceptions::NotFound.new(@client.logger))
          @client.should_receive(:api_get_request).with(
            "/job/test_job/1/").ordered.and_return({})
          @client.should_receive(:get_jenkins_version).and_return("1.1")
          @job.build("test_job", {}, {'build_start_timeout' => 3}).should == 1
        end

        # wait for build to start - will fail
        it "accepts the job name and builds the job, but the job doesn't start" do
          @client.should_receive(:api_get_request).with(
            "/job/test_job").and_return({})
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return(FakeResponse.new(302))
          @client.should_receive(:api_get_request).with(
            "/job/test_job/1/").twice.ordered.and_raise(JenkinsApi::Exceptions::NotFound.new(@client.logger))
          @client.should_receive(:get_jenkins_version).and_return("1.1")
          expect( lambda { @job.build("test_job", {}, {'build_start_timeout' => 3}) }).to raise_error(Timeout::Error)
        end

        ### JENKINS POST 1.519 (QUEUE RESPONSE) ###
        # Next tests confirm it deals with different jenkins versions and waits
        # for build to start (or not)
        it "accepts the job name and builds the job (w/timeout)" do
          @client.should_receive(:api_get_request).with(
            "/job/test_job").and_return({})
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return({"location" => "/item/42/"})
          @client.should_receive(:api_get_request).with(
            "/queue/item/42").and_return({'executable' => {'number' => 1}})
          @client.should_receive(:get_jenkins_version).and_return("1.519")
          @job.build("test_job", {}, {'build_start_timeout' => 10}).should == 1
        end

        # wait for build to start (or not) (initial response will fail)
        it "accepts the job name and builds the job after short delay (w/timeout)" do
          @client.should_receive(:api_get_request).with(
            "/job/test_job").and_return({})
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return({"location" => "/item/42/"})
          @client.should_receive(:api_get_request).with(
            "/queue/item/42").and_return({}, {'executable' => {'number' => 1}})
          @client.should_receive(:get_jenkins_version).and_return("1.519")
          @job.build("test_job", {}, {'build_start_timeout' => 3}).should == 1
        end

        # wait for build to start - will fail
        it "accepts the job name and builds the job, but the job doesn't start" do
          @client.should_receive(:api_get_request).with(
            "/job/test_job").and_return({})
          @client.should_receive(:api_post_request).with(
            "/job/test_job/build", {}, true).and_return({"location" => "/item/42/"})
          @client.should_receive(:api_get_request).with(
            "/queue/item/42").and_return({}, {})
          @client.should_receive(:get_jenkins_version).and_return("1.519")
          expect( lambda { @job.build("test_job", {}, {'build_start_timeout' => 3}) }).to raise_error(Timeout::Error)
        end
      end

      describe "#poll" do
        it "accepts the job name and polls the job for scm changes" do
          @client.should_receive(:api_post_request).with(
            "/job/test_job/polling"
          ).and_return(302)
          @job.poll("test_job").should == 302
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
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.unchain(["test_job"])
        end
      end

      describe "#chain" do
        it "accepts the job names and other options and chains them" do
          @client.should_receive(:get_config).with(
            "/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.unchain(["test_job"])
        end
      end

      describe "#get_promotions" do
        it "accepts the jon name and returns the promotions" do
            mock_job_promotions_response = {
              "processes" => [ { "name"  => "dev",
                                 "url"   => "not_required",
                                 "color" => "blue",
                               },
                               { "name"  => "stage",
                                 "url"   => "not_required",
                                 "color" => "notbuilt",
                               },
                             ], }

          @client.should_receive(:api_get_request).with('/job/test_job/promotion').and_return(
            mock_job_promotions_response)
          @client.should_receive(:api_get_request).and_return({'target' => {'number' => 42}})
          @job.get_promotions("test_job").should == {'dev' => 42, 'stage' => nil}
        end
      end

      describe "#get_promote_config" do
        it "accepts name and process and returns promotion config" do
          @client.should_receive(:get_config).with('/job/testjob/promotion/process/promo/config.xml')
          @job.get_promote_config('testjob', 'promo')
        end
      end

      describe "#set_promote_config" do
        it "accepts name, process and config." do
          @client.should_receive(:post_config).with('/job/testjob/promotion/process/promo/config.xml', 'xml')
          @job.set_promote_config('testjob', 'promo', 'xml')
        end
      end

      describe "#delete_promote_config" do
        it "accepts name and process and deletes promotion config" do
          @client.should_receive(:post_config).with('/job/testjob/promotion/process/promo/doDelete')
          @job.delete_promote_config('testjob', 'promo')
        end
      end

      describe '#scm_git' do
        before do
          @job.send(:scm_git, {
            scm_url: 'http://foo.bar',
            scm_credentials_id: 'foobar',
            scm_branch: 'master',
            scm_git_tool: 'Git_NoPath',
          }, xml_builder=Nokogiri::XML::Builder.new(:encoding => 'UTF-8'))
          @xml_config = Nokogiri::XML(xml_builder.to_xml)
        end

        it 'adds scm_url to hudson.plugins.git.UserRemoteConfig userRemoteConfig url tag' do
          expect(@xml_config.at_css('scm userRemoteConfigs url').content).to eql('http://foo.bar')
        end

        it 'adds scm_credentials_id to hudson.plugins.git.UserRemoteConfig userRemoteConfig credentialsId tag' do
          expect(@xml_config.at_css('scm userRemoteConfigs credentialsId').content).to eql('foobar')
        end

        it 'adds branch to scm branches' do
          expect(@xml_config.at_css('scm branches name').content).to eql('master')
        end

        it 'adds gitTool to scm tag' do
          expect(@xml_config.at_css('scm gitTool').content).to eql('Git_NoPath')
        end
      end

      describe "#get_build_details" do
        it "accepts job name and build number" do
          @client.should_receive(:api_get_request).and_return(@sample_json_build_response)
          job_name = 'test_job'
          response = @job.get_build_details(job_name, 1)
          response.class.should == Hash
        end

        it "accepts job name and gets latest build number if build number is 0" do
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response, @sample_json_build_response)
          job_name = 'test_job'
          response = @job.get_build_details(job_name, 0)
          response.class.should == Hash
        end
      end

      describe "#find_artifact" do
        it "accepts job name and build number and return artifact path" do
          expected_path = CGI.escape("https://example.com/DEFAULT-VIEW/view/VIEW-NAME/job/test_job/2/artifact/somepath/output.json") 
          @client.should_receive(:api_get_request).and_return(@sample_json_build_response)
          expect(@job.find_artifact('test_job', 1)).to eql(expected_path)
        end

        it "accepts job name and uses latest build number if build number not provided and return artifact path" do
          expected_path = CGI.escape("https://example.com/DEFAULT-VIEW/view/VIEW-NAME/job/test_job/2/artifact/somepath/output.json") 
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response, @sample_json_build_response)
          expect(@job.find_artifact('test_job')).to eql(expected_path)
        end

        it "raises if artifact is missing" do
          modified_response = JSON.parse(@sample_json_build_response.to_json)
          modified_response.delete('artifacts')
          @client.should_receive(:api_get_request).and_return(modified_response)
          expect(lambda { @job.find_artifact('test_job', 1) }).to raise_error("No artifacts found.")
        end

        it "raises if artifact array is missing" do
          modified_response = JSON.parse(@sample_json_build_response.to_json)
          modified_response['artifacts'].clear()
          @client.should_receive(:api_get_request).and_return(modified_response)
          expect(lambda { @job.find_artifact('test_job', 1) }).to raise_error("No artifacts found.")
        end

        it "raises if artifact array has no relative path" do
          modified_response = JSON.parse(@sample_json_build_response.to_json)
          modified_response['artifacts'].first.delete('relativePath')
          @client.should_receive(:api_get_request).and_return(modified_response)
          expect(lambda { @job.find_artifact('test_job', 1) }).to raise_error("No artifacts found.")
        end
      end

      describe "#artifact_exists?" do
        it "accepts job name and build number and returns true when artifact exists and has path" do
          @client.should_receive(:api_get_request).and_return(@sample_json_build_response)
          expect(@job.artifact_exists?('test_job', 1)).to eql(true)
        end

        it "accepts job name and uses latest build number if build number is 0 and returns true when artifact exists and has path" do
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response, @sample_json_build_response)
          expect(@job.artifact_exists?('test_job', 0)).to eql(true)
        end

        it "returns false if missing artifacts from json" do
          modified_response = JSON.parse(@sample_json_build_response.to_json)
          modified_response.delete('artifacts')
          @client.should_receive(:api_get_request).and_return(modified_response)
          expect(@job.artifact_exists?('test_job', 1)).to eql(false)
        end

        it "returns false if artifacts is empty array" do
          modified_response = JSON.parse(@sample_json_build_response.to_json)
          modified_response['artifacts'].clear()
          @client.should_receive(:api_get_request).and_return(modified_response)
          expect(@job.artifact_exists?('test_job', 1)).to eql(false)
        end

        it "returns false if no relative path is included in first artifact" do
          modified_response = JSON.parse(@sample_json_build_response.to_json)
          modified_response['artifacts'].first.delete('relativePath')
          @client.should_receive(:api_get_request).and_return(modified_response)
          expect(@job.artifact_exists?('test_job', 1)).to eql(false)
        end
      end
    end

    describe '#build_freestyle_config' do
      it 'calls configure on its plugin collection' do
        expect(@job.plugin_collection).to receive(:configure).and_return(Nokogiri::XML::Document.new(''))
        @job.build_freestyle_config(name: 'foobar')
      end

      context 'scm_trigger and ignore_post_commit_hooks params' do
        it 'configures triggers with a hudson.triggers.SCMTrigger' do
          xml = @job.build_freestyle_config(
            name: 'foobar',
            scm_trigger: 'H 0 29 2 0',
            ignore_post_commit_hooks: true
          )

          xml_config = Nokogiri::XML(xml)
          expect(xml_config.at_css('triggers spec').content).to eql('H 0 29 2 0')
          expect(xml_config.at_css('triggers ignorePostCommitHooks').content).to eql('true')
        end

        it 'does not add a tag to triggers if not passed scm_trigger param' do
          xml = @job.build_freestyle_config(
            name: 'foobar'
          )

          xml_config = Nokogiri::XML(xml)
          expect(xml_config.at_css('triggers').children).to be_empty
        end
      end

      context 'artifact archiver build step' do
        context 'given artifact_archiver params' do
          it 'configures with given params' do
            artifact_archiver_params = {
              artifact_files: '**',
              excludes: 'foo',
              fingerprint: true,
              allow_empty_archive: true,
              only_if_successful: true,
              default_excludes: true,
            }
            xml = @job.build_freestyle_config(
              name: 'foobar',
              artifact_archiver: artifact_archiver_params,
            )
            xml_config = Nokogiri::XML(xml)

            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/artifacts').content).to eql('**')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/excludes').content).to eql('foo')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/fingerprint').content).to eql('true')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/allowEmptyArchive').content).to eql('true')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/onlyIfSuccessful').content).to eql('true')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/defaultExcludes').content).to eql('true')
          end

          it 'configures with defaults for non-specified options' do
            xml = @job.build_freestyle_config(
              name: 'foobar',
              artifact_archiver: {},
            )
            xml_config = Nokogiri::XML(xml)

            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/artifacts').content).to eql('')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/excludes').content).to eql('')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/fingerprint').content).to eql('false')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/allowEmptyArchive').content).to eql('false')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/onlyIfSuccessful').content).to eql('false')
            expect(xml_config.at_xpath('//publishers/hudson.tasks.ArtifactArchiver/defaultExcludes').content).to eql('false')
          end
        end

        context 'not given artifact_archiver params' do
          it 'omits hudson.tasks.ArtifactArchiver tag' do
            xml = @job.build_freestyle_config(name: 'foobar')
            xml_config = Nokogiri::XML(xml)

            expect(xml_config.xpath('//publishers/hudson.tasks.ArtifactArchiver')).to be_empty
          end
        end
      end
    end

    context 'plugin settings' do
      let(:plugin) { JenkinsApi::Client::PluginSettings::Base.new }
      describe '#add_plugin' do
        it 'calls add on @plugin_collection with given plugin setting' do
          expect(@job.plugin_collection).to receive(:add).with(plugin)
          @job.add_plugin(plugin)
        end
      end

      describe '#remove_plugin' do
        it 'calls remove on @plugin_collection with given plugin setting' do
          expect(@job.plugin_collection).to receive(:remove).with(plugin)
          @job.remove_plugin(plugin)
        end
      end
    end
  end
end
