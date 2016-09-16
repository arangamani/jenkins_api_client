#
# Helper functions for Ruby specifications
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require 'simplecov'
SimpleCov.start if ENV["COVERAGE"]
require File.expand_path('../../../lib/jenkins_api_client', __FILE__)
require 'pp'
require 'yaml'
require 'nokogiri'

module JenkinsApiSpecHelper
  class Helper
    def create_job_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
        xml.project {
          xml.actions
          xml.description
          xml.keepDependencies "false"
          xml.properties
          xml.scm(:class => "hudson.scm.NullSCM")
          xml.canRoam "true"
          xml.disabled "false"
          xml.blockBuildWhenDownstreamBuilding "false"
          xml.blockBuildWhenUpstreamBuilding "false"
          xml.triggers.vector
          xml.concurrentBuild "false"
          xml.builders {
            xml.send("hudson.tasks.Shell") {
              xml.command "\necho 'going to take a nice nap'\nsleep 15\necho 'took a nice nap'"
            }
          }
          xml.publishers
          xml.buildWrappers
        }
      }
      builder.to_xml
    end

    def create_job_with_params_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
        xml.project {
          xml.actions
          xml.description
          xml.keepDependencies "false"
          xml.properties {
              xml.send("hudson.model.ParametersDefinitionProperty") {
                  xml.parameterDefinitions {
                      xml.send("hudson.model.StringParameterDefinition") {
                          xml.name "PARAM1"
                      }
                  }
              }
          }
          xml.scm(:class => "hudson.scm.NullSCM")
          xml.canRoam "true"
          xml.disabled "false"
          xml.assignedNode "none"
          xml.blockBuildWhenDownstreamBuilding "false"
          xml.blockBuildWhenUpstreamBuilding "false"
          xml.triggers.vector
          xml.concurrentBuild "false"
          xml.builders {
            xml.send("hudson.tasks.Shell") {
              xml.command "\necho 'going to take a nice nap'\nsleep 15\necho 'took a nice nap'"
            }
          }
          xml.publishers
          xml.buildWrappers
        }
      }
      builder.to_xml
    end
  end
end
