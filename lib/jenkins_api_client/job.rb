module JenkinsApi
  class Client
    class Job

      # Initialize the Job object and store the reference to Client object
      #
      def initialize(client)
        @client = client
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

      # List all jobs that match the given regex
      #
      # @param [String] filter - a regex
      #
      def list(filter)
        response_json = @client.api_get_request("")
        jobs = []
        response_json["jobs"].each { |job|
          jobs << job["name"] if job["name"] =~ /#{filter}/i
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

      # Obtain the current build status of the job
      # By defaule Jenkins returns the color of the job status icon
      # This function translates the color into a meaningful status
      #
      # @param [String] job_name
      #
      def get_current_build_status(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        case response_json["color"]
        when "blue"
          "success"
        when "red"
          "failure"
        when "yellow"
          "unstable"
        when "grey_anime", "blue_anime", "red_anime"
          "running"
        when "grey"
          "not run"
        when "aborted"
          "aborted"
        end
      end

      # This functions lists all jobs that are currently running on the Jenkins CI server
      #
      def list_running
        jobs = list_all
        running_jobs = []
        jobs.each { |job|
          running_jobs << job if get_current_build_status(job) == "running"
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
        @client.post_config("/job/#{job_name}", xml)
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
      #
      def add_downstream_projects(job_name, downstream_projects, threshold = 'success')
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
          child_projects_node.content = child_projects_node.content + ", #{downstream_projects}"
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

    end
  end
end
