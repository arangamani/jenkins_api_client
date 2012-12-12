#
# Copyright (c) 2012 Kannan Manickam <arangamani.kannan@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

module JenkinsApi
  class Client
    class Job

      # Initialize the Job object and store the reference to Client object
      #
      def initialize(client)
        @client = client
      end

      # Return a string representation of the object
      #
      def to_s
        "#<JenkinsApi::Client::Job>"
      end

      # Create a job with the name specified and the xml given
      #
      # @param [String] job_name
      # @param [XML] xml
      #
      def create(job_name, xml)
        @client.post_config("/createItem?name=#{job_name}", xml)
      end

      # Delete a job given the name
      #
      # @param [String] job_name
      #
      def delete(job_name)
        @client.api_post_request("/job/#{job_name}/doDelete")
      end

      # Stops a running build of a job
      # This method will stop the current/most recent build if no build number
      # is specified. The build will be stopped only if it was in 'running' state.
      #
      # @param [String] job_name
      # @param [Number] build_number
      #
      def stop_build(job_name, build_number = 0)
        build_number = get_current_build_number(job_name) if build_number == 0
        raise "No builds for #{job_name}" unless build_number
        # Check and see if the build is running
        is_building = @client.api_get_request("/job/#{job_name}/#{build_number}")["building"]
        @client.api_post_request("/job/#{job_name}/#{build_number}/stop") if is_building
      end

      # Re-create the same job
      # This is a hack to clear any existing builds
      #
      # @param [String] job_name
      #
      def recreate(job_name)
        job_xml = get_config(job_name)
        delete(job_name)
        create(job_name, job_xml)
      end

      # List all jobs on the Jenkins CI server
      #
      def list_all
        response_json = @client.api_get_request("")
        jobs = []
        response_json["jobs"].each { |job|
          jobs << job["name"]
        }
        jobs.sort!
      end

      # Checks if the given job exists in Jenkins
      #
      # @param [String] job_name
      #
      def exists?(job_name)
        list(job_name).include?(job_name) ? true : false
      end

      # List all Jobs matching the given status
      # You can optionally pass in jobs list to filter the status from
      #
      # @param [String] status
      # @param [Array] jobs
      #
      def list_by_status(status, jobs = [])
        jobs = list_all if jobs.empty?
        xml_response = @client.api_get_request("", "tree=jobs[name,color]")
        filtered_jobs = []
        xml_response["jobs"].each { |job|
          filtered_jobs << job["name"] if color_to_status(job["color"]) == status && jobs.include?(job["name"])
        }
        filtered_jobs
      end

      # List all jobs that match the given regex
      #
      # @param [String] filter - a regex
      # @param [Boolean] ignorecase
      #
      def list(filter, ignorecase = true)
        response_json = @client.api_get_request("")
        jobs = []
        response_json["jobs"].each { |job|
          if ignorecase
            jobs << job["name"] if job["name"] =~ /#{filter}/i
          else
            jobs << job["name"] if job["name"] =~ /#{filter}/
          end
        }
        jobs
      end

      # List all jobs on the Jenkins CI server along with their details
      #
      def list_all_with_details
       response_json = @client.api_get_request("")
       response_json["jobs"]
      end

      # List details of a specific job
      #
      # @param [String] job_name
      #
      def list_details(job_name)
        @client.api_get_request("/job/#{job_name}")
      end

      # List upstream projects of a specific job
      #
      # @param [String] job_name
      #
      def get_upstream_projects(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["upstreamProjects"]
      end

      # List downstream projects of a specific job
      #
      # @param [String] job_name
      #
      def get_downstream_projects(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["downstreamProjects"]
      end

      # Obtain build details of a specific job
      #
      # @param [String] job_name
      #
      def get_builds(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["builds"]
      end

      # This method maps the color to status of a job
      #
      # @param [String] color color given by the API for a job
      #
      def color_to_status(color)
        case color
        when "blue"
          "success"
        when "red"
          "failure"
        when "yellow"
          "unstable"
        when "grey_anime", "blue_anime", "red_anime"
          "running"
        when "grey"
          "not_run"
        when "aborted"
          "aborted"
        else
          "invalid"
        end
      end

      # Obtain the current build status of the job
      # By defaule Jenkins returns the color of the job status icon
      # This function translates the color into a meaningful status
      #
      # @param [String] job_name
      #
      def get_current_build_status(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        color_to_status(response_json["color"])
      end

      # Obtain the current build number of the given job
      # This function returns nil if there were no builds for the given job name.
      #
      # @param [String] job_name
      #
      def get_current_build_number(job_name)
        builds = get_builds(job_name)
        builds.length > 0 ? builds.first["number"] : nil
      end

      # This functions lists all jobs that are currently running on the Jenkins CI server
      # This method is deprecated. Please use list_by_status instead.
      #
      def list_running
        puts "[WARN] list_running is deprecated. Please use list_by_status('running') instead."
        xml_response = @client.api_get_request("", "tree=jobs[name,color]")
        running_jobs = []
        xml_response["jobs"].each { |job|
          running_jobs << job["name"] if color_to_status(job["color"]) == "running"
        }
        running_jobs
      end

      # Build a job given the name of the job
      #
      # @param [String] job_name
      #
      def build(job_name)
        @client.api_post_request("/job/#{job_name}/build")
      end

      # Obtain the configuration stored in config.xml of a specific job
      #
      # @param [String] job_name
      #
      def get_config(job_name)
        @client.get_config("/job/#{job_name}")
      end

      # Post the configuration of a job given the job name and the config.xml
      #
      # @param [String] job_name
      # @param [String] xml
      #
      def post_config(job_name, xml)
        @client.post_config("/job/#{job_name}/config.xml", xml)
      end

      # Change the description of a specific job
      #
      # @param [String] job_name
      # @param [String] description
      #
      def change_description(job_name, description)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        desc = n_xml.xpath("//description").first
        desc.content = "#{description}"
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Add downstream projects to a specific job given the job name, projects to be
      # added as downstream projects, and the threshold
      #
      # @param [String] job_name
      # @param [String] downstream_projects
      # @param [String] threshold - failure, success, or unstable
      # @param [Bool] overwrite - true or false
      #
      def add_downstream_projects(job_name, downstream_projects, threshold, overwrite = false)
        case threshold
        when 'success'
          name = 'SUCCESS'
          ordinal = 0
          color = 'BLUE'
        when 'unstable'
          name = 'UNSTABLE'
          ordinal = 1
          color = 'YELLOW'
        when 'failure'
          name = 'FAILURE'
          ordinal = 2
          color = 'RED'
        end
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        child_projects_node = n_xml.xpath("//childProjects").first
        if child_projects_node
          if overwrite
            child_projects_node.content = "#{downstream_projects}"
          else
            child_projects_node.content = child_projects_node.content + ", #{downstream_projects}"
          end
        else
          publisher_node = n_xml.xpath("//publishers").first
          build_trigger_node = publisher_node.add_child("<hudson.tasks.BuildTrigger/>")
          child_project_node = build_trigger_node.first.add_child("<childProjects>#{downstream_projects}</childProjects>")
          threshold_node = child_project_node.first.add_next_sibling("<threshold/>")
          threshold_node.first.add_child("<name>#{name}</name><ordinal>#{ordinal}</ordinal><color>#{color}</color>")
        end
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Remove all downstream projects of a specific job
      #
      # @param [String] job_name
      #
      def remove_downstream_projects(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        n_xml.search("//hudson.tasks.BuildTrigger").each{ |node|
          child_project_trigger = false
          node.search("//childProjects").each { |child_node|
            child_project_trigger = true
            child_node.search("//threshold").each { |threshold_node|
              threshold_node.children.each { |threshold_value_node|
                threshold_value_node.content = nil
                threshold_value_node.remove
              }
              threshold_node.content = nil
              threshold_node.remove
            }
            child_node.content = nil
            child_node.remove
          }
          node.content = nil
          node.remove
        }
        publisher_node = n_xml.search("//publishers").first
        publisher_node.content = nil if publisher_node.children.empty?
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Resctrict the given job to a specific node
      #
      # @param [String] job_name
      # @param [String] node_name
      #
      def restrict_to_node(job_name, node_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        if (node = n_xml.xpath("//assignedNode").first)
          node.content = node_name
        else
          project = n_xml.xpath("//scm").first
          child_node = project.add_next_sibling("<assignedNode>#{node_name}</assignedNode>")
          roam_node = n_xml.xpath("//canRoam").first
          roam_node.content = "false"
        end
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Unchain any existing chain between given job names
      #
      # @param [Array] job_names Array of job names to be unchained
      #
      def unchain(job_names)
        job_names.each { |job|
          puts "[INFO] Removing downstream projects for <#{job}>" if @client.debug
          @client.job.remove_downstream_projects(job)
        }
      end

      # Chain the jobs given based on specified criteria
      #
      # @param [Array] job_names Array of job names to be chained
      # @param [String] threshold what should be the threshold for running the next job
      # @param [Array] criteria criteria which should be applied for picking the jobs for the chain
      # @param [Integer] parallel Number of jobs that should be considered for parallel run
      #
      def chain(job_names, threshold, criteria, parallel = 1)
        raise "Parallel jobs should be at least 1" if parallel < 1
        unchain(job_names)
        filtered_job_names = []
        if criteria.include?("all") || criteria.empty?
          filtered_job_names = job_names
        else
          puts "[INFO] Criteria is specified. Filtering jobs..." if @client.debug
          job_names.each { |job|
            filtered_job_names << job if criteria.include?(@client.job.get_current_build_status(job))
          }
        end
        filtered_job_names.each_with_index { |job_name, index|
          break if index >= (filtered_job_names.length - parallel)
          puts "[INFO] Adding <#{filtered_job_names[index+1]}> as a downstream project to <#{job_name}> with <#{threshold}> as the threshold" if @client.debug
          @client.job.add_downstream_projects(job_name, filtered_job_names[index + parallel], threshold, true)
        }
        parallel = filtered_job_names.length if parallel > filtered_job_names.length
        filtered_job_names[0..parallel-1]
      end

    end
  end
end
