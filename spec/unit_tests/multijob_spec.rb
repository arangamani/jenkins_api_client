require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::Multijob do

  before do
    mock_logger = Logger.new "/dev/null"
    @client = double
    @client.should_receive(:logger).and_return(mock_logger)
    @multijob = JenkinsApi::Client::Multijob.new(@client)
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
    @sample_multijob_xml = File.read(
        File.expand_path('../fixtures/files/multijob_sample.xml', __FILE__))
  end

  describe :phase do

    it :build_multi_job do
      branch = 'ABC'
      command = 'SomeCommand'
      params = {
        :phase => {:name => 'Cukes', :jobs => [
          {:name => 'ABC-SPEC'},
          {:name => 'ABC-CUKE1'},
          {:name => 'ABC-CUKE2'}
        ]},
        :name => branch,
        :restricted_node => 'selfservice',
        :scm_provider => "git",
        :scm_url => "git@github.com:USER/Repo.git",
        :scm_branch => "origin/#{branch}",
        :shell_command => "#{command}",
        :scm_trigger => '*/5 * * * *',
        :build_wrappers_xvfb => true,
        :build_wrappers_ansicolor => true,
        :log_rotator => true,
        :s3_artifact_publisher => {
              profile: 'JenkinsUser',
              bucket: 'the/bucket/that/it/goes/in',
              tar_file: 'ABC-build.tar.gz',
              region: 'S3_REGION'
          },
          :git => { fast_remote_polling: true }
      }

      generated_multijob_xml = @multijob.build_multi_job_config(params)
      generated_multijob_xml.gsub(/\s+/, '').should eq @sample_multijob_xml.gsub(/\s+/, '')

    end

    describe :phase do

        it 'generates a MultiJobBuilder xml node' do
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          @multijob.phase({:name =>'SomeName', :jobs => [{:name => 'ABC-SPEC'}]},xml)
        end

        builder.to_xml.gsub(/\s+/, '').should eq phase_job_config_xml.gsub(/\s+/, '')
      end
    end
  end

  private

  def phase_job_config_xml
%q{<?xml version="1.0" encoding="UTF-8"?>
<com.tikal.jenkins.plugins.multijob.MultiJobBuilder plugin="jenkins-multijob-plugin@1.12">
  <phaseName>SomeName</phaseName>
  <phaseJobs>
    <com.tikal.jenkins.plugins.multijob.PhaseJobsConfig>
      <jobName>ABC-SPEC</jobName>
      <currParams>true</currParams>
      <exposedSCM>false</exposedSCM>
      <disableJob>false</disableJob>
      <configs class="empty-list"/>
      <killPhaseOnJobResultCondition>NEVER</killPhaseOnJobResultCondition>
    </com.tikal.jenkins.plugins.multijob.PhaseJobsConfig>
  </phaseJobs>
  <continuationCondition>SUCCESSFUL</continuationCondition>
</com.tikal.jenkins.plugins.multijob.MultiJobBuilder>}
  end

end
