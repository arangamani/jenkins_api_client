#
# Copyright (c) 2012-2013 Kannan Manickam <arangamani.kannan@gmail.com>
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
        @client.post_config("/createItem?name=#{encoded_job_name(job_name)}", xml)
      end

      # Create a job with params given as a hash instead of the xml
      # This gives some flexibility for creating simple jobs so the user
      # doesn't have to learn about handling xml.
      #
      # @param [Hash] params
      #  * +:name+ name of the job
      #  * +:keep_dependencies+ true or false
      #  * +:block_build_when_downstream_building+ true or false
      #  * +:block_build_when_upstream_building+ true or false
      #  * +:concurrent_build+ true or false
      #  * +:scm_provider+ type of source control system. Supported: Git, SVN
      #  * +:scm_url+ remote url for scm
      #  * +:scm_module+ Module to download. Only for CVS.
      #  * +:scm_branch+ branch to use in scm. Uses master by default
      #  * +:scm_tag+ tag to download from scm. Only for CVS.
      #  * +:scm_use_head_if_tag_not_found+ Only for CVS.
      #  * +:shell_command+ command to execute in the shell
      #  * +:child_projects+ projects to add as downstream projects
      #  * +:child_threshold+ threshold for child projects.
      #      success, failure, or unstable. Default: failure.
      #
      # @example Create a Freestype Project
      #   create_freestyle(
      #     :name => "test_freestyle_job",
      #     :keep_dependencies => true,
      #     :concurrent_build => true,
      #     :scm_provider => "git",
      #     :scm_url => "git://github.com./arangamani/jenkins_api_client.git",
      #     :scm_branch => "master",
      #     :shell_command => "bundle install\n rake func_tests"
      #   )
      #
      def create_freestyle(params)
        # Supported SCM providers
        supported_scm = ["git", "subversion", "cvs"]

        # Set default values for params that are not specified.
        raise 'Job name must be specified' unless params[:name]
        if params[:keep_dependencies].nil?
          params[:keep_dependencies] = false
        end
        if params[:block_build_when_downstream_building].nil?
          params[:block_build_when_downstream_building] = false
        end
        if params[:block_build_when_upstream_building].nil?
          params[:block_build_when_upstream_building] = false
        end
        params[:concurrent_build] = false if params[:concurrent_build].nil?
        if params[:notification_email]
          if params[:notification_email_for_every_unstable_build].nil?
            params[:notification_email_for_every_unstable] = false
          end
          if params[:notification_email_send_to_individuals].nil?
            params[:notification_email_send_to_individuals] ||= false
          end
        end

        # SCM configurations and Error handling.
        unless supported_scm.include?(params[:scm_provider]) ||
          params[:scm_provider].nil?
          raise "SCM #{params[:scm_provider]} is currently not supported"
        end
        if params[:scm_url].nil? && !params[:scm_provider].nil?
          raise 'SCM URL must be specified'
        end
        if params[:scm_branch].nil? && !params[:scm_provider].nil?
          params[:scm_branch] = "master"
        end
        if params[:scm_use_head_if_tag_not_found].nil?
          params[:scm_use_head_if_tag_not_found] = false
        end

        # Child projects configuration and Error handling
        if params[:child_threshold].nil? && !params[:child_projects].nil?
          params[:child_threshold] = 'failure'
        end

        # Build the Job xml file based on the parameters given
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
          xml.project {
            xml.actions
            xml.description
            xml.keepDependencies "#{params[:keep_dependencies]}"
            xml.properties
            # SCM related stuff
            if params[:scm_provider] == 'subversion'
              xml.scm(:class => "hudson.scm.SubversionSCM",
                      :plugin => "subversion@1.39") {
                xml.locations {
                  xml.send("hudson.scm.SubversionSCM_-ModuleLocation") {
                    xml.remote "#{params[:scm_url]}"
                    xml.local "."
                  }
                }
                xml.excludedRegions
                xml.includedRegions
                xml.excludedUsers
                xml.excludedRevprop
                xml.excludedCommitMessages
                xml.workspaceUpdater(:class =>
                                     "hudson.scm.subversion.UpdateUpdater")
              }
            elsif params[:scm_provider] == "cvs"
              xml.scm(:class => "hudson.scm.CVSSCM",
                      :plugin => "cvs@1.6") {
                xml.cvsroot "#{params[:scm_url]}"
                xml.module "#{params[:scm_module]}"
                if params[:scm_branch]
                  xml.branch "#{params[:scm_branch]}"
                else
                  xml.branch "#{params[:scm_tag]}"
                end
                xml.canUseUpdate true
                xml.useHeadIfNotFound(
                  "#{params[:scm_use_head_if_tag_not_found]}")
                xml.flatten true
                if params[:scm_tag]
                  xml.isTag true
                else
                  xml.isTag false
                end
                xml.excludedRegions
              }
            elsif params[:scm_provider] == "git"
              xml.scm(:class => "hudson.plugins.git.GitSCM") {
                xml.configVersion "2"
                xml.userRemoteConfigs {
                  xml.send("hudson.plugins.git.UserRemoteConfig") {
                    xml.name
                    xml.refspec
                    xml.url "#{params[:scm_url]}"
                  }
                }
                xml.branches {
                  xml.send("hudson.plugins.git.BranchSpec") {
                    xml.name "#{params[:scm_branch]}"
                  }
                }
                xml.disableSubmodules "false"
                xml.recursiveSubmodules "false"
                xml.doGenerateSubmoduleConfigurations "false"
                xml.authorOrCommitter "false"
                xml.clean "false"
                xml.wipeOutWorkspace "false"
                xml.pruneBranches "false"
                xml.remotePoll "false"
                xml.ignoreNotifyCommit "false"
                xml.useShallowClone "false"
                xml.buildChooser(:class =>
                                 "hudson.plugins.git.util.DefaultBuildChooser")
                xml.gitTool "Default"
                xml.submoduleCfg(:class => "list")
                xml.relativeTargetDir
                xml.reference
                xml.excludedRegions
                xml.excludedUsers
                xml.gitConfigName
                xml.gitConfigEmail
                xml.skipTag "false"
                xml.includedRegions
                xml.scmName
              }
            else
              xml.scm(:class => "hudson.scm.NullSCM")
            end
            # Restrict job to run in a specified node
            if params[:restricted_node]
              xml.assignedNode "#{params[:restricted_node]}"
              xml.canRoam "false"
            else
              xml.canRoam "true"
            end
            xml.disabled "false"
            xml.blockBuildWhenDownstreamBuilding(
              "#{params[:block_build_when_downstream_building]}")
            xml.blockBuildWhenUpstreamBuilding(
              "#{params[:block_build_when_upstream_building]}")
            xml.triggers.vector
            xml.concurrentBuild "#{params[:concurrent_build]}"
            # Shell command stuff
            xml.builders {
              if params[:shell_command]
                xml.send("hudson.tasks.Shell") {
                  xml.command "#{params[:shell_command]}"
                }
              end
            }
            # Adding Downstream projects
            xml.publishers {
              if params[:child_projects]
                xml.send("hudson.tasks.BuildTrigger") {
                  xml.childProjects "#{params[:child_projects]}"
                  threshold = params[:child_threshold]
                  name, ordinal, color = get_threshold_params(threshold)
                  xml.threshold {
                    xml.name "#{name}"
                    xml.ordinal "#{ordinal}"
                    xml.color "#{color}"
                  }
                }
              end
              if params[:notification_email]
                xml.send("hudson.tasks.Mailer") {
                  xml.recipients "#{params[:notification_email]}"
                  xml.dontNotifyEveryUnstableBuild(
                    "#{params[:notification_email_for_every_unstable]}")
                  xml.sendToIndividuals(
                    "#{params[:notification_email_send_to_individuals]}")
                }
              end
            }
            xml.buildWrappers
          }
        }
        create(params[:name], builder.to_xml)
      end

      # Delete a job given the name
      #
      # @param [String] job_name
      #
      def delete(job_name)
        @client.api_post_request("/job/#{encoded_job_name(job_name)}/doDelete")
      end

      # Deletes all jobs from Jenkins
      #
      # @note This method will remove all jobs from Jenkins. Please use with
      #       caution.
      #
      def delete_all!
        list_all.each { |job| delete(job) }
      end

      # Stops a running build of a job
      # This method will stop the current/most recent build if no build number
      # is specified. The build will be stopped only if it was
      # in 'running' state.
      #
      # @param [String] job_name
      # @param [Number] build_number
      #
      def stop_build(job_name, build_number = 0)
        build_number = get_current_build_number(job_name) if build_number == 0
        raise "No builds for #{job_name}" unless build_number
        # Check and see if the build is running
        is_building = @client.api_get_request(
          "/job/#{encoded_job_name(job_name)}/#{build_number}"
        )["building"]
        if is_building
          @client.api_post_request("/job/#{encoded_job_name(job_name)}/#{build_number}/stop")
        end
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

      # Get progressive console output from Jenkins server for a job
      #
      # @param [String] job_name Name of the Jenkins job
      # @param [Number] build_num Specific build number to obtain the
      #                 console output from. Default is the recent build
      # @param [Number] start start offset to get only a portion of the text
      # @param [String] mode Mode of text output. 'text' or 'html'
      #
      # @return [Hash] response
      #   * +output+ Console output of the job
      #   * +size+ Size of the text. This can be used as 'start' for the
      #            next call to get progressive output
      #   * +more+ More data available for the job. 'true' if available
      #            and nil otherwise
      #
      def get_console_output(job_name, build_num = 0, start = 0, mode = 'text')
        build_num = get_current_build_number(job_name) if build_num == 0
        if build_num == 0
          puts "No builds for this job '#{job_name}' yet."
          return nil
        end
        if mode == 'text'
          mode = 'Text'
        elsif mode == 'html'
          mode = 'Html'
        else
          raise "Mode should either be 'text' or 'html'. You gave: #{mode}"
        end
        get_msg = "/job/#{encoded_job_name(job_name)}/#{build_num}/logText/progressive#{mode}?"
        get_msg << "start=#{start}"
        api_response = @client.api_get_request(get_msg, nil, nil)
        #puts "Response: #{api_response.header['x-more-data']}"
        response = {}
        response['output'] = api_response.body
        response['size'] = api_response.header['x-text-size']
        response['more'] = api_response.header['x-more-data']

        response
      end

      # List all jobs on the Jenkins CI server
      #
      def list_all
        response_json = @client.api_get_request("")
        jobs = []
        response_json["jobs"].each { |job| jobs << job["name"] }
        jobs.sort!
      end

      # Checks if the given job exists in Jenkins
      #
      # @param [String] job_name
      #
      def exists?(job_name)
        list(job_name).include?(job_name)
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
        xml_response["jobs"].each do |job|
          if color_to_status(job["color"]) == status &&
             jobs.include?(job["name"])
            filtered_jobs << job["name"]
          end
        end
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
        response_json["jobs"].each do |job|
          if ignorecase
            jobs << job["name"] if job["name"] =~ /#{filter}/i
          else
            jobs << job["name"] if job["name"] =~ /#{filter}/
          end
        end
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
        @client.api_get_request("/job/#{encoded_job_name(job_name)}")
      end

      # List upstream projects of a specific job
      #
      # @param [String] job_name
      #
      def get_upstream_projects(job_name)
        response_json = @client.api_get_request("/job/#{encoded_job_name(job_name)}")
        response_json["upstreamProjects"]
      end

      # List downstream projects of a specific job
      #
      # @param [String] job_name
      #
      def get_downstream_projects(job_name)
        response_json = @client.api_get_request("/job/#{encoded_job_name(job_name)}")
        response_json["downstreamProjects"]
      end

      # Obtain build details of a specific job
      #
      # @param [String] job_name
      #
      def get_builds(job_name)
        response_json = @client.api_get_request("/job/#{encoded_job_name(job_name)}")
        response_json["builds"]
      end

      # This method maps the color to status of a job
      #
      # @param [String] color color given by the API for a job
      #
      # @return [String] status status of the given job matching the color
      #
      def color_to_status(color)
        case color
        when "blue"
          "success"
        when "red"
          "failure"
        when "yellow"
          "unstable"
        when /anime/
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
      # @return [String] status current status of the given job
      #
      def get_current_build_status(job_name)
        response_json = @client.api_get_request("/job/#{encoded_job_name(job_name)}")
        color_to_status(response_json["color"])
      end

      # Obtain the current build number of the given job
      # This function returns nil if there were no builds for the given job.
      #
      # @param [String] job_name
      #
      # @return [Number] build_unumber current build number of the given job
      #
      def get_current_build_number(job_name)
        @client.api_get_request("/job/#{encoded_job_name(job_name)}")['nextBuildNumber'].to_i - 1
      end

      # Build a job given the name of the job
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def build(job_name)
        @client.api_post_request("/job/#{encoded_job_name(job_name)}/build")
      end

      # Build a job given the name of the job
      #
      # @param [String] job_name
      # @param [Hash] params
      #
      # @return [String] response_code return code from HTTP POST
      #
      def build_with_params(job_name, params={})
        @client.api_post_request("/job/#{encoded_job_name(job_name)}/buildWithParameters", params)
      end

      # Obtain the configuration stored in config.xml of a specific job
      #
      # @param [String] job_name
      #
      # @return [String] XML Config.xml of the job
      #
      def get_config(job_name)
        @client.get_config("/job/#{encoded_job_name(job_name)}")
      end

      # Post the configuration of a job given the job name and the config.xml
      #
      # @param [String] job_name
      # @param [String] xml
      #
      # @return [String] response_code return code from HTTP POST
      #
      def post_config(job_name, xml)
        @client.post_config("/job/#{encoded_job_name(job_name)}/config.xml", xml)
      end

      # Change the description of a specific job
      #
      # @param [String] job_name
      # @param [String] description
      #
      # @return [String] response_code return code from HTTP POST
      #
      def change_description(job_name, description)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        desc = n_xml.xpath("//description").first
        desc.content = "#{description}"
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Block the build of the job when downstream is building
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def block_build_when_downstream_building(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        node = n_xml.xpath("//blockBuildWhenDownstreamBuilding").first
        if node.content == "false"
          node.content = "true"
          xml_modified = n_xml.to_xml
          post_config(job_name, xml_modified)
        end
      end

      # Unblock the build of the job when downstream is building
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def unblock_build_when_downstream_building(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        node = n_xml.xpath("//blockBuildWhenDownstreamBuilding").first
        if node.content == "true"
          node.content = "false"
          xml_modified = n_xml.to_xml
          post_config(job_name, xml_modified)
        end
      end

      # Block the build of the job when upstream is building
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def block_build_when_upstream_building(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        node = n_xml.xpath("//blockBuildWhenUpstreamBuilding").first
        if node.content == "false"
          node.content = "true"
          xml_modified = n_xml.to_xml
          post_config(job_name, xml_modified)
        end
      end

      # Unblock the build of the job when upstream is building
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def unblock_build_when_upstream_building(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        node = n_xml.xpath("//blockBuildWhenUpstreamBuilding").first
        if node.content == "true"
          node.content = "false"
          xml_modified = n_xml.to_xml
          post_config(job_name, xml_modified)
        end
      end

      # Allow or disable concurrent build execution
      #
      # @param [String] job_name
      # @param [Bool] option true or false
      #
      # @return [String] response_code return code from HTTP POST
      #
      def execute_concurrent_builds(job_name, option)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        node = n_xml.xpath("//concurrentBuild").first
        if node.content != "#{option}"
          node.content = option == true ? "true" : "false"
          xml_modified = n_xml.to_xml
          post_config(job_name, xml_modified)
        end
      end

      # Obtain the build parameters of a job. It returns an array of hashes with
      # details of job params.
      #
      # @param [String] job_name
      #
      # @return [Array] params_array Array of parameters for the given job
      #
      def get_build_params(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        params = n_xml.xpath("//parameterDefinitions").first
        params_array = []
        if params
          params.children.each do |param|
            param_hash = {}
            case param.name
            when "hudson.model.StringParameterDefinition",
                 "hudson.model.BooleanParameterDefinition",
                 "hudson.model.TextParameterDefinition",
                 "hudson.model.PasswordParameterDefinition"
              param_hash[:type] = 'string' if param.name =~ /string/i
              param_hash[:type] = 'boolean' if param.name =~ /boolean/i
              param_hash[:type] = 'text' if param.name =~ /text/i
              param_hash[:type] = 'password' if param.name =~ /password/i
              param.children.each do |value|
                param_hash[:name] = value.content if value.name == "name"
                if value.name == "description"
                  param_hash[:description] = value.content
                end
                if value.name == "defaultValue"
                  param_hash[:default] = value.content
                end
              end
            when "hudson.model.RunParameterDefinition"
              param_hash[:type] = 'run'
              param.children.each do |value|
                param_hash[:name] = value.content if value.name == "name"
                if value.name == "description"
                  param_hash[:description] = value.content
                end
                if value.name == "projectName"
                  param_hash[:project] = value.content
                end
              end
            when "hudson.model.FileParameterDefinition"
              param_hash[:type] = 'file'
              param.children.each do |value|
                param_hash[:name] = value.content if value.name == "name"
                if value.name == "description"
                  param_hash[:description] = value.content
                end
              end
            when "hudson.scm.listtagsparameter.ListSubversionTagsParameterDefinition"
              param_hash[:type] = 'list_tags'
              param.children.each do |value|
                if value.name == "name"
                  param_hash[:name] = value.content
                end
                if value.name == "description"
                  param_hash[:description] = value.content
                end
                if value.name == "tagsDir"
                  param_hash[:tags_dir] = value.content
                end
                if value.name == "tagsFilter"
                  param_hash[:tags_filter] = value.content
                end
                if value.name == "reverseByDate"
                  param_hash[:reverse_by_date] = value.content
                end
                if value.name == "reverseByName"
                  param_hash[:reverse_by_name] = value.content
                end
                if value.name == "defaultValue"
                  param_hash[:default] = value.content
                end
                param_hash[:max_tags] = value.content if value.name == "maxTags"
                param_hash[:uuid] = value.content if value.name == "uuid"
              end
            when "hudson.model.ChoiceParameterDefinition"
              param_hash[:type] = 'choice'
              param.children.each do |value|
                param_hash[:name] = value.content if value.name == "name"
                param_hash[:description] = value.content \
                  if value.name == "description"
                choices = []
                if value.name == "choices"
                  value.children.each do |value_child|
                    if value_child.name == "a"
                      value_child.children.each do |choice_child|
                        choices << choice_child.content.strip \
                          unless choice_child.content.strip.empty?
                      end
                    end
                  end
                end
                param_hash[:choices] = choices unless choices.empty?
              end
            end
            params_array << param_hash unless param_hash.empty?
          end
        end
        params_array
      end

      # Obtains the threshold params used by jenkins in the XML file
      # given the threshold
      #
      # @param [String] threshold success, failure, or unstable
      #
      # @return [String] status readable status matching the color
      #
      def get_threshold_params(threshold)
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
        return name, ordinal, color
      end

      # Add downstream projects to a specific job given the job name,
      # projects to be added as downstream projects, and the threshold
      #
      # @param [String] job_name
      # @param [String] downstream_projects
      # @param [String] threshold - failure, success, or unstable
      # @param [Bool] overwrite - true or false
      #
      # @return [String] response_code return code from HTTP POST
      #
      def add_downstream_projects(job_name,
                                  downstream_projects,
                                  threshold, overwrite = false)
        name, ord, col = get_threshold_params(threshold)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        child_projects_node = n_xml.xpath("//childProjects").first
        if child_projects_node
          if overwrite
            child_projects_node.content = "#{downstream_projects}"
          else
            to_replace = child_projects_node.content +
              ", #{downstream_projects}"
            child_projects_node.content = to_replace
          end
        else
          publisher_node = n_xml.xpath("//publishers").first
          build_trigger_node = publisher_node.add_child(
            "<hudson.tasks.BuildTrigger/>"
          )
          child_project_node = build_trigger_node.first.add_child(
            "<childProjects>#{downstream_projects}</childProjects>"
          )
          threshold_node = child_project_node.first.add_next_sibling(
            "<threshold/>"
          )
          threshold_node.first.add_child(
            "<name>#{name}</name><ordinal>#{ord}</ordinal><color>#{col}</color>"
          )
        end
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Remove all downstream projects of a specific job
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def remove_downstream_projects(job_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        n_xml.search("//hudson.tasks.BuildTrigger").each do |node|
          child_project_trigger = false
          node.search("//childProjects").each do |child_node|
            child_project_trigger = true
            child_node.search("//threshold").each do |threshold_node|
              threshold_node.children.each do |threshold_value_node|
                threshold_value_node.content = nil
                threshold_value_node.remove
              end
              threshold_node.content = nil
              threshold_node.remove
            end
            child_node.content = nil
            child_node.remove
          end
          node.content = nil
          node.remove
        end
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
      # @return [String] response_code return code from HTTP POST
      #
      def restrict_to_node(job_name, node_name)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        if (node = n_xml.xpath("//assignedNode").first)
          node.content = node_name
        else
          project = n_xml.xpath("//scm").first
          project.add_next_sibling("<assignedNode>#{node_name}</assignedNode>")
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
        job_names.each do |job|
          log_msg = "[INFO] Removing downstream projects for <#{job}>"
          puts log_msg if @client.debug
          remove_downstream_projects(job)
        end
      end

      # Chain the jobs given based on specified criteria
      #
      # @param [Array] job_names Array of job names to be chained
      # @param [String] threshold threshold for running the next job
      # @param [Array] criteria criteria which should be applied for
      #                picking the jobs for the chain
      # @param [Integer] parallel Number of jobs that should be considered
      #                  for parallel run
      #
      # @return [Array] job_names Names of jobs that are in the top of the
      #                 chain
      def chain(job_names, threshold, criteria, parallel = 1)
        raise "Parallel jobs should be at least 1" if parallel < 1
        unchain(job_names)

        filtered_job_names = []
        if criteria.include?("all") || criteria.empty?
          filtered_job_names = job_names
        else
          log_msg = "[INFO] Criteria is specified. Filtering jobs..."
          puts log_msg if @client.debug
          job_names.each do |job|
            filtered_job_names << job if criteria.include?(
              @client.job.get_current_build_status(job)
            )
          end
        end

        filtered_job_names.each_with_index do |job_name, index|
          break if index >= (filtered_job_names.length - parallel)
          msg = "[INFO] Adding <#{filtered_job_names[index+1]}> as a"
          msg << " downstream project to <#{job_name}> with <#{threshold}> as"
          msg << " the threshold"
          puts msg if @client.debug
          @client.job.add_downstream_projects(
            job_name, filtered_job_names[index + parallel], threshold, true
          )
        end
        if parallel > filtered_job_names.length
          parallel = filtered_job_names.length
        end
        filtered_job_names[0..parallel-1]
      end

      def encoded_job_name(job_name)
        URI.escape(job_name)
      end

    end
  end
end
