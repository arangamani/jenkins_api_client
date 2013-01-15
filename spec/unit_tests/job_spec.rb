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
      @sample_job_xml = File.read(File.expand_path('../fixtures/files/job_sample.xml', __FILE__))
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
        it "accepts a hash of parameters and creates the job" do
          params = {:name => 'test_job'}
          @client.should_receive(:post_config)
          @job.create_freestyle(params)
        end
      end

      describe "#delete" do
        it "accepts the job name and deletes the job" do
          @client.should_receive(:api_post_request)
          @job.delete('test_job')
        end
      end

      describe "#stop_build" do
        it "accepts the job name and build number and stops the specified build" do
          @client.should_receive(:api_get_request).twice.and_return("building" => true, "nextBuildNumber" => 2)
          @client.should_receive(:api_post_request)
          @job.stop_build('test_job')
        end
      end

      describe "#get_console_output" do
        it "accepts the job name, build number, start, and mode and the obtains the console output from server" do
          @client.should_receive(:api_get_request).and_return(Net::HTTP.get_response(URI('http://example.com/index.html')))
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
          @client.should_receive(:api_get_request).and_return(@sample_json_response)
          response = @job.list_all
          response.class.should == Array
          response.size.should == @sample_json_response["jobs"].size
        end
      end

      describe "#exists?" do
        it "accepts a job name and returns true if the job exists on the server" do
          @client.should_receive(:api_get_request).and_return(@sample_json_response)
          @job.exists?("test_job").should == true
        end
      end

      describe "#list_by_status" do
        it "accepts the status and returns jobs in specified status" do
          @client.should_receive(:api_get_request).twice.and_return(@sample_json_response)
          @job.list_by_status("success").class.should == Array
        end
        it "accepts the status and jobs and returns the jobs in specified status" do
          @client.should_receive(:api_get_request).and_return(@sample_json_response)
          @job.list_by_status("success", ["test_job"]).class.should == Array
        end
      end

      describe "#list" do
        it "accepts a filter and returns all jobs matching the filter" do
          @client.should_receive(:api_get_request).and_return("jobs" => ["test_job"])
          @job.list("filter").class.should == Array
        end
      end

      describe "#list_all_with_details" do
        it "accepts no parameters and returns all jobs with details" do
          @client.should_receive(:api_get_request).and_return(@sample_json_response)
          response = @job.list_all_with_details
          response.class.should == Array
          response.size.should == @sample_json_response["jobs"].size
        end
      end

      describe "#list_details" do
        it "accepts the job name and returns its details" do
          @client.should_receive(:api_get_request).and_return(@sample_json_response)
          response = @job.list_details("test_job")
          response.class.should == Hash
        end
      end

      describe "#get_upstream_projects" do
        it "accepts the job name and returns its upstream projects" do
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response)
          response = @job.get_upstream_projects("test_job")
          response.class.should == Array
        end
      end

      describe "#get_downstream_projects" do
        it "accepts the job name and returns its downstream projects" do
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response)
          response = @job.get_downstream_projects("test_job")
          response.class.should == Array
        end
      end

      describe "#get_builds" do
        it "accepts the job name and returns its builds" do
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response)
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
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response)
          @job.get_current_build_status("test_job").class.should == String
        end
      end

      describe "#get_current_build_number" do
        it "accepts the job name and returns its current build number" do
          @client.should_receive(:api_get_request).and_return(@sample_json_job_response)
          @job.get_current_build_number("test_job").class.should == Fixnum
        end
      end

      describe "#build" do
        it "accepts the job name and builds the job" do
          @client.should_receive(:api_post_request).with("/job/test_job/build").and_return(302)
          @job.build("test_job").should == 302
        end
      end

      describe "#get_config" do
        it "accepts the job name and obtains its config.xml" do
          @client.should_receive(:get_config).with("/job/test_job").and_return("<job>test_job</job>")
          @job.get_config("test_job").should == "<job>test_job</job>"
        end
      end

      describe "#post_config" do
        it "accepts the job name and posts its config.xml to the server" do
          @client.should_receive(:post_config).with("/job/test_job/config.xml", "<job>test_job</job>")
          @job.post_config("test_job", "<job>test_job</job>")
        end
      end

      describe "#change_description" do
        it "accepts the job name and description and changes it" do
          @client.should_receive(:get_config).with("/job/test_job").and_return(@sample_job_xml)
          @client.should_receive(:post_config)
          @job.change_description("test_job", "new description")
        end
      end

    end
  end
end
