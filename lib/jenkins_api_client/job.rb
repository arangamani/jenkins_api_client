module JenkinsApi
  class Client
    class Job

      def initialize(client)
        @client = client
      end

      def test_method
        puts "Username is: #{@client}"
      end

      def list_all
        response_json = @client.api_get_request("")
        jobs = []
        response_json["jobs"].each { |job|
          jobs << job["name"]
        }
        jobs.sort!
      end

      def list(filter)
        response_json = @client.api_get_request("")
        jobs = []
        response_json["jobs"].each { |job|
          jobs << job["name"] if job["name"] =~ /#{filter}/i
        }
        jobs
      end

      def list_all_with_details
       response_json = @client.api_get_request("")
       response_json["jobs"]
      end

      def list_details(job_name)
        @client.api_get_request("/job/#{job_name}")
      end

      def get_upstream_projects(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["upstreamProjects"]
      end

      def get_downstream_projects(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["downstreamProjects"]
      end

      def get_builds(job_name)
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["builds"]
      end

      def build(job_name)
        @client.api_post_request("/job/#{job_name}/build")
      end

      def get_config(job_name)
        @client.get_config("/job/#{job_name}")
      end

      def post_config(job_name, xml)
        @client.post_config("/job/#{job_name}", xml)
      end

      def change_description(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        desc = n_xml.xpath("//description").first
        desc.content = "Some description"
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      def add_downstream_projects(job_name, downstream_project, threshold = 'success')
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
          child_projects_node.content = child_projects_node.content + ", #{downstream_project}"
        else
          publisher_node = n_xml.xpath("//publishers").first
          build_trigger_node = publisher_node.add_child("<hudson.tasks.BuildTrigger/>")
          child_project_node = build_trigger_node.first.add_child("<childProjects>#{downstream_project}</childProjects>")
          threshold_node = child_project_node.first.add_next_sibling("<threshold/>")
          threshold_node.first.add_child("<name>#{name}</name><ordinal>#{ordinal}</ordinal><color>#{color}</color>")
        end
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

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
