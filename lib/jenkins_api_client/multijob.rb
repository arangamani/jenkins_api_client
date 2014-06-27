module JenkinsApi
  class Client
    class Multijob < Job

      def create_multijob(params)
        xml = build_multi_job_config(params)
        create(params[:name], xml)
      end

      def build_multi_job_config(params)

        # Build the Job xml file based on the parameters given
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.send('com.tikal.jenkins.plugins.multijob.MultiJobProject', :plugin => 'jenkins-multijob-plugin@1.12') do
            xml.actions
            xml.description
            xml.keepDependencies false
            xml.properties
            scm_git(params, xml)
            xml.assignedNode 'selfservice'
            xml.canRoam false
            xml.disabled false
            xml.blockBuildWhenDownstreamBuilding false
            xml.blockBuildWhenUpstreamBuilding false
            xml.triggers.vector do
              xml.send('hudson.triggers.SCMTrigger') do
                xml.spec '*/5 * * * *'
              end
            end
            xml.concurrentBuild false
            xml.builders do
              xml.send('org.jenkinsci.plugins.conditionalbuildstep.ConditionalBuilder', :plugin => 'conditional-buildstep@1.3.3') do
                xml.runner(:class => 'org.jenkins_ci.plugins.run_condition.BuildStepRunner$Fail', :plugin => 'run-condition@1.0')
                xml.runCondition(:class => 'org.jenkins_ci.plugins.run_condition.core.AlwaysRun', :plugin => 'run-condition@1.0')
                xml.conditionalbuilders do
                  phase(params[:phase], xml)
                end
              end
              if params[:shell_command]
                xml.send("hudson.tasks.Shell") do
                  xml.command "#{params[:shell_command]}"
                end
              end
            end
            xml.publishers do
              # Build portion of XML that adds s3 artifacts publisher
              s3_publisher(params, xml) if params[:s3_artifact_publisher]
            end
          end
        end
        builder.to_xml
      end

      def phase(phase, xml)
        xml.send('com.tikal.jenkins.plugins.multijob.MultiJobBuilder', :plugin => 'jenkins-multijob-plugin@1.12') do
          xml.phaseName phase[:name]
          xml.phaseJobs do
            phase[:jobs].each do |job_params|
              xml.send('com.tikal.jenkins.plugins.multijob.PhaseJobsConfig') do
                xml.jobName "#{job_params[:name]}"
                xml.currParams true
                xml.exposedSCM false
                xml.disableJob false
                xml.configs(:class => 'empty-list')
                xml.killPhaseOnJobResultCondition 'NEVER'
              end
            end
          end
          xml.continuationCondition 'SUCCESSFUL'
        end
      end

    end
  end
end

