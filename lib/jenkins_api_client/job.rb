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
    # This class communicates with the Jenkins "/job" API to obtain details
    # about jobs, creating, deleting, building, and various other operations.
    #
    class Job

      # Initialize the Job object and store the reference to Client object
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
      end

      # Return a string representation of the object
      #
      def to_s
        "#<JenkinsApi::Client::Job>"
      end

      # Create or Update a job with the name specified and the xml given
      #
      # @param job_name [String] the name of the job
      # @param xml [String] the xml configuration of the job
      #
      # @see #create
      # @see #update
      #
      # @return [String] the HTTP status code from the POST request
      #
      def create_or_update(job_name, xml)
        if exists?(name)
          update(job_name, xml)
        else
          create(job_name, xml)
        end
      end

      # Create a job with the name specified and the xml given
      #
      # @param job_name [String] the name of the job
      # @param xml [String] the xml configuration of the job
      #
      # @see #create_or_update
      # @see #update
      #
      # @return [String] the HTTP status code from the POST request
      #
      def create(job_name, xml)
        @logger.info "Creating job '#{job_name}'"
        @client.post_config("/createItem?name=#{job_name}", xml)
      end

      # Update a job with the name specified and the xml given
      #
      # @param job_name [String] the name of the job
      # @param xml [String] the xml configuration of the job
      #
      # @see #create_or_update
      # @see #create
      #
      # @return [String] the HTTP status code from the POST request
      #
      def update(job_name, xml)
        @logger.info "Updating job '#{job_name}'"
        post_config(job_name, xml)
      end

      # Create or Update a job with params given as a hash instead of the xml
      # This gives some flexibility for creating/updating simple jobs so the
      # user doesn't have to learn about handling xml.
      #
      # @param params [Hash] parameters to create a freestyle project
      #
      # @option params [String] :name+
      #   the name of the job
      # @option params [Boolean] :keep_dependencies (false)
      #   whether to keep the dependencies or not
      # @option params [Boolean] :block_build_when_downstream_building (false)
      #   whether to block build when the downstream project is building
      # @option params [Boolean] :block_build_when_upstream_building (false)
      #   whether to block build when the upstream project is building
      # @option params [Boolean] :concurrent_build (false)
      #   whether to allow concurrent execution of builds
      # @option params [String] :scm_provider
      #   the type of source control. Supported providers: git, svn, and cvs
      # @option params [String] :scm_url
      #   the remote url for the selected scm provider
      # @option params [String] :scm_module
      #   the module to download. Only for use with "cvs" scm provider
      # @option params [String] :scm_branch (master)
      #   the branch to use in scm.
      # @option params [String] :scm_tag
      #   the tag to download from scm. Only for use with "cvs" scm provider
      # @option params [Boolean] :scm_use_head_if_tag_not_found
      #   whether to use head if specified tag is not found. Only for "cvs"
      # @option params [String] :timer
      #   the timer for running builds periodically
      # @option params [String] :shell_command
      #   the command to execute in the shell
      # @option params [String] :notification_email
      #   the email for sending notification
      # @option params [String] :skype_targets
      #   the skype targets for sending notifications to. Use * to specify
      #   group chats. Use space to separate multiple targets. Note that this
      #   option requires the "skype" plugin to be installed in jenkins.
      #   Example: testuser *testgroup
      # @option params [String] :skype_strategy (change)
      #   the skype strategy to be used for sending notifications.
      #   Valid values: all, failure, failure_and_fixed, change.
      # @option params [Boolean] :skype_notify_on_build_start (false)
      #   whether to notify skype targets on build start
      # @option params [Boolean] :skype_notify_suspects (false)
      #   whether to notify suspects on skype
      # @option params [Boolean] :skype_notify_culprits (false)
      #   whether to notify culprits on skype
      # @option params [Boolean] :skype_notify_fixers (false)
      #   whether to notify fixers on skype
      # @option params [Boolean] :skype_notify_upstream_committers (false)
      #   whether to notify upstream committers on skype
      # @option params [String] :skype_message (summary_and_scm_changes)
      #   the information to be sent as notification message. Valid:
      #   just_summary, summary_and_scm_changes,
      #   summary_and_build_parameters, summary_scm_changes_and_failed_tests.
      # @option params [String] :child_projects
      #   the projects to add as downstream projects
      # @option params [String] :child_threshold (failure)
      #   the threshold for child projects. Valid options: success, failure,
      #   or unstable.
      #
      # @see #create_freestyle
      # @see #update_freestyle
      #
      # @return [String] the HTTP status code from the POST request
      #
      def create_or_update_freestyle(params)
        if exists?(params[:name])
          update_freestyle(params)
        else
          create_freestyle(params)
        end
      end

      # Create a freestyle project by accepting a Hash of parameters. For the
      # parameter description see #create_of_update_freestyle
      #
      # @param params [Hash] the parameters for creating a job
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
      # @see #create_or_update_freestyle
      # @see #create
      # @see #update_freestyle
      #
      # @return [String] the HTTP status code from the POST request
      #
      def create_freestyle(params)
        xml = build_freestyle_config(params)
        create(params[:name], xml)
      end

      # Update a job with params given as a hash instead of the xml. For the
      # parameter description see #create_or_update_freestyle
      #
      # @param params [Hash]
      #
      # @see #create_or_update_freestyle
      # @see #update
      # @see #create_freestyle
      #
      # @return [String] the HTTP status code from the POST request
      #
      def update_freestyle(params)
        xml = build_freestyle_config(params)
        update(params[:name], xml)
      end

      # Builds the XML configuration based on the parameters passed as a Hash
      #
      # @param params [Hash] the parameters for building XML configuration
      #
      # @return [String] the generated XML configuration of the project
      #
      def build_freestyle_config(params)
        # Supported SCM providers
        supported_scm = ["git", "subversion", "cvs"]

        # Set default values for params that are not specified.
        raise ArgumentError, "Job name must be specified" \
          unless params.is_a?(Hash) && params[:name]

        [
          :keep_dependencies,
          :block_build_when_downstream_building,
          :block_build_when_upstream_building,
          :concurrent_build
        ].each do |param|
          params[param] = false if params[param].nil?
        end

        if params[:notification_email]
          if params[:notification_email_for_every_unstable].nil?
            params[:notification_email_for_every_unstable] = false
          end
          if params[:notification_email_send_to_individuals].nil?
            params[:notification_email_send_to_individuals] ||= false
          end
        end

        # SCM configurations and Error handling.

        unless params[:scm_provider].nil?
          unless supported_scm.include?(params[:scm_provider])
            raise "SCM #{params[:scm_provider]} is currently not supported"
          end
          raise "SCM URL must be specified" if params[:scm_url].nil?
          params[:scm_branch] = "master" if params[:scm_branch].nil?
          if params[:scm_use_head_if_tag_not_found].nil?
            params[:scm_use_head_if_tag_not_found] = false
          end
        end

        # Child projects configuration and Error handling
        if params[:child_threshold].nil? && !params[:child_projects].nil?
          params[:child_threshold] = "failure"
        end

        @logger.debug "Creating a freestyle job with params: #{params.inspect}"

        # Build the Job xml file based on the parameters given
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.project do
            xml.actions
            xml.description
            xml.keepDependencies "#{params[:keep_dependencies]}"
            xml.properties
            # SCM related stuff
            if params[:scm_provider] == 'subversion'
              # Build subversion related XML portion
              scm_subversion(params, xml)
            elsif params[:scm_provider] == "cvs"
              # Build CVS related XML portion
              scm_cvs(params, xml)
            elsif params[:scm_provider] == "git"
              # Build Git related XML portion
              scm_git(params, xml)
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
            if params[:timer]
              xml.triggers.vector do
                xml.send("hudson.triggers.TimerTrigger") do
                  xml.spec params[:timer]
                end
              end
            else
              xml.triggers.vector
            end
            xml.concurrentBuild "#{params[:concurrent_build]}"
            # Shell command stuff
            xml.builders do
              if params[:shell_command]
                xml.send("hudson.tasks.Shell") do
                  xml.command "#{params[:shell_command]}"
                end
              end
            end
            # Adding Downstream projects
            xml.publishers do
              # Build portion of XML that adds child projects
              child_projects(params, xml) if params[:child_projects]
              # Build portion of XML that adds email notification
              notification_email(params, xml) if params[:notification_email]
              # Build portion of XML that adds skype notification
              skype_notification(params, xml) if params[:skype_targets]
            end
            xml.buildWrappers
          end
        end
        builder.to_xml
      end


      # Adding email notification to a job
      #
      # @param [Hash] params parameters to add email notification
      #
      # @option params [String] :name Name of the job
      # @option params [String] :notification_email Email address to send
      # @option params [Boolean] :notification_email_for_every_unstable
      # Send email notification email for every unstable build
      #
      def add_email_notification(params)
        raise "No job name specified" unless params[:name]
        raise "No email address specified" unless params[:notification_email]
        @logger.info "Adding '#{params[:notification_email]}' to be" +
          " notified for '#{params[:name]}'"
        xml = get_config(params[:name])
        n_xml = Nokogiri::XML(xml)
        if n_xml.xpath("//hudson.tasks.Mailer").empty?
          p_xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |b_xml|
            notification_email(params, b_xml)
          end
          email_xml = Nokogiri::XML(p_xml.to_xml).xpath(
            "//hudson.tasks.Mailer"
          ).first
          n_xml.xpath("//publishers").first.add_child(email_xml)
          post_config(params[:name], n_xml.to_xml)
        end
      end

      # Adding skype notificaiton to a job
      #
      # @param [Hash] params parameters for adding skype notification
      #  * +:name+ name of the job to add skype notification
      #  * +:skype_targets+ skype targets for sending notifications to. Use *
      #    to specify group chats. Use space to separate multiple targets.
      #    Example: testuser, *testgroup.
      #  * +:skype_strategy+ skype strategy to be used for sending
      #    notifications. Valid values: all, failure, failure_and_fixed,
      #    change. Default: change.
      #  * +:skype_notify_on_build_start+ Default: false
      #  * +:skype_notify_suspects+ Default: false
      #  * +:skype_notify_culprits+ Default: false
      #  * +:skype_notify_fixers+ Default: false
      #  * +:skype_notify_upstream_committers+ Default: false
      #  * +:skype_message+ what should be sent as notification message. Valid:
      #    just_summary, summary_and_scm_changes, summary_and_build_parameters,
      #    summary_scm_changes_and_failed_tests.
      #    Default: summary_and_scm_changes
      #
      def add_skype_notification(params)
        raise "No job name specified" unless params[:name]
        raise "No Skype target specified" unless params[:skype_targets]
        @logger.info "Adding Skype notification for '#{params[:name]}'"
        xml = get_config(params[:name])
        n_xml = Nokogiri::XML(xml)
        if n_xml.xpath("//hudson.plugins.skype.im.transport.SkypePublisher").empty?
          p_xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |b_xml|
            skype_notification(params, b_xml)
          end
          skype_xml = Nokogiri::XML(p_xml.to_xml).xpath(
            "//hudson.plugins.skype.im.transport.SkypePublisher"
          ).first
          n_xml.xpath("//publishers").first.add_child(skype_xml)
          post_config(params[:name], n_xml.to_xml)
        end
      end

      # Rename a job given the old name and new name
      #
      # @param [String] old_job Name of the old job
      # @param [String] new_job Name of the new job.
      #
      def rename(old_job, new_job)
        @logger.info "Renaming job '#{old_job}' to '#{new_job}'"
        @client.api_post_request("/job/#{old_job}/doRename?newName=#{new_job}")
      end

      # Delete a job given the name
      #
      # @param [String] job_name
      #
      def delete(job_name)
        @logger.info "Deleting job '#{job_name}'"
        @client.api_post_request("/job/#{job_name}/doDelete")
      end

      # Deletes all jobs from Jenkins
      #
      # @note This method will remove all jobs from Jenkins. Please use with
      #       caution.
      #
      def delete_all!
        @logger.info "Deleting all jobs from jenkins"
        list_all.each { |job| delete(job) }
      end

      # Wipe out the workspace for a job given the name
      #
      # @param [String] job_name
      #
      def wipe_out_workspace(job_name)
        @logger.info "Wiping out the workspace of job '#{job_name}'"
        @client.api_post_request("/job/#{job_name}/doWipeOutWorkspace")
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
        @logger.info "Stopping job '#{job_name}' Build ##{build_number}"
        # Check and see if the build is running
        is_building = @client.api_get_request(
          "/job/#{job_name}/#{build_number}"
        )["building"]
        if is_building
          @client.api_post_request("/job/#{job_name}/#{build_number}/stop")
        end
      end

      # Re-create the same job
      # This is a hack to clear any existing builds
      #
      # @param [String] job_name
      #
      def recreate(job_name)
        @logger.info "Recreating job '#{job_name}'"
        job_xml = get_config(job_name)
        delete(job_name)
        create(job_name, job_xml)
      end

      # Copy a job
      #
      # @param [String] from_job_name
      # @param [String] to_job_name
      #
      def copy(from_job_name, to_job_name=nil)
        to_job_name = "copy_of_#{from_job_name}" if to_job_name.nil?
        @logger.info "Copying job '#{from_job_name}' to '#{to_job_name}'"
        @client.api_post_request(
          "/createItem?name=#{to_job_name}&mode=copy&from=#{from_job_name}"
        )
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
      #   next call to get progressive output
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
        get_msg = "/job/#{job_name}/#{build_num}/logText/progressive#{mode}?"
        get_msg << "start=#{start}"
        raw_response = true
        api_response = @client.api_get_request(get_msg, nil, nil, raw_response)
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
        response_json = @client.api_get_request("", "tree=jobs[name]")["jobs"]
        response_json.map { |job| job["name"] }.sort
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
        @logger.info "Obtaining jobs matching status '#{status}'"
        json_response = @client.api_get_request("", "tree=jobs[name,color]")
        filtered_jobs = []
        json_response["jobs"].each do |job|
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
        @logger.info "Obtaining jobs matching filter '#{filter}'"
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
        @logger.info "Obtaining the details of all jobs"
        response_json = @client.api_get_request("")
        response_json["jobs"]
      end

      # List details of a specific job
      #
      # @param [String] job_name
      #
      def list_details(job_name)
        @logger.info "Obtaining the details of '#{job_name}'"
        @client.api_get_request("/job/#{job_name}")
      end

      # List upstream projects of a specific job
      #
      # @param [String] job_name
      #
      def get_upstream_projects(job_name)
        @logger.info "Obtaining the upstream projects of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["upstreamProjects"]
      end

      # List downstream projects of a specific job
      #
      # @param [String] job_name
      #
      def get_downstream_projects(job_name)
        @logger.info "Obtaining the down stream projects of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{job_name}")
        response_json["downstreamProjects"]
      end

      # Obtain build details of a specific job
      #
      # @param [String] job_name
      #
      def get_builds(job_name)
        @logger.info "Obtaining the build details of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{job_name}")
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
        # In the recent version of Jenkins (> 1.517), jobs that are not built
        # yet have a color of "notbuilt" instead of "grey". Include that to the
        # not_run condition so it is backward compatible.
        when "grey", "notbuilt"
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
        @logger.info "Obtaining the current build status of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{job_name}")
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
        @logger.info "Obtaining the current build number of '#{job_name}'"
        @client.api_get_request("/job/#{job_name}")['nextBuildNumber'].to_i - 1
      end

      # Build a job given the name of the job
      # You can optionally pass in a list of params for Jenkins to use for
      # parameterized builds
      #
      # @param [String] job_name the name of the job
      # @param [Hash] params the parameters for parameterized builds
      # @param [Boolean] return_build_number whether to wait and obtain the build
      #   number
      #
      # @return [String, Integer] the response code from the build POST request
      #   if return_build_number is not requested and the build number if the
      #   return_build_number is requested. nil will be returned if the build
      #   number is requested and not available. This can happen if there is
      #   already a job in the queue and concurrent build is disabled.
      #
      def build(job_name, params={}, return_build_number = false)
        msg = "Building job '#{job_name}'"
        msg << " with parameters: #{params.inspect}" unless params.empty?
        @logger.info msg
        build_endpoint = params.empty? ? "build" : "buildWithParameters"
        raw_response = return_build_number
        response =@client.api_post_request(
          "/job/#{job_name}/#{build_endpoint}",
          params,
          raw_response
        )
        # If return_build_number is enabled, obtain the queue ID from the location
        # header and wait till the build is moved to one of the executors and a
        # build number is assigned
        if return_build_number
          if response["location"]
            task_id_match = response["location"].match(/\/item\/(\d*)\//)
            task_id = task_id_match.nil? ? nil : task_id_match[1]
            unless task_id.nil?
              @logger.debug "Queue task ID for job '#{job_name}': #{task_id}"
              Timeout::timeout(@client.timeout) do
                while @client.queue.get_item_by_id(task_id)["executable"].nil?
                  sleep 5
                end
              end
              @client.queue.get_item_by_id(task_id)["executable"]["number"]
            else
              nil
            end
          else
            nil
          end
        else
          response
        end
      end

      # Enable a job given the name of the job
      #
      # @param [String] job_name
      #
      def enable(job_name)
        @logger.info "Enabling job '#{job_name}'"
        @client.api_post_request("/job/#{job_name}/enable")
      end

      # Disable a job given the name of the job
      #
      # @param [String] job_name
      #
      def disable(job_name)
        @logger.info "Disabling job '#{job_name}'"
        @client.api_post_request("/job/#{job_name}/disable")
      end

      # Obtain the configuration stored in config.xml of a specific job
      #
      # @param [String] job_name
      #
      # @return [String] XML Config.xml of the job
      #
      def get_config(job_name)
        @logger.info "Obtaining the config.xml of '#{job_name}'"
        @client.get_config("/job/#{job_name}")
      end

      # Post the configuration of a job given the job name and the config.xml
      #
      # @param [String] job_name
      # @param [String] xml
      #
      # @return [String] response_code return code from HTTP POST
      #
      def post_config(job_name, xml)
        @logger.info "Posting the config.xml of '#{job_name}'"
        @client.post_config("/job/#{job_name}/config.xml", xml)
      end

      # Obtain the test results for a specific build of a job
      #
      # @param [String] job_name
      # @param [Number] build_num
      #
      def get_test_results(job_name, build_num)
        build_num = get_current_build_number(job_name) if build_num == 0
        @logger.info "Obtaining the test results of '#{job_name}'" +
          " Build ##{build_num}"
        @client.api_get_request("/job/#{job_name}/#{build_num}/testReport")
      rescue Exceptions::NotFound
        # Not found is acceptable, as not all builds will have test results
        # and this is what jenkins throws at us in that case
        nil
      end

      # Obtain detailed build info for a job
      #
      # @param [String] job_name
      # @param [Number] build_num
      #
      def get_build_details(job_name, build_num)
        build_num = get_current_build_number(job_name) if build_num == 0
        @logger.info "Obtaining the build details of '#{job_name}'" +
          " Build ##{build_num}"

        @client.api_get_request("/job/#{job_name}/#{build_num}/")
      end

      # Change the description of a specific job
      #
      # @param [String] job_name
      # @param [String] description
      #
      # @return [String] response_code return code from HTTP POST
      #
      def change_description(job_name, description)
        @logger.info "Changing the description of '#{job_name}' to '#{description}'"
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
        @logger.info "Blocking builds of '#{job_name}' when downstream" +
          " projects are building"
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
        @logger.info "Unblocking builds of '#{job_name}' when downstream" +
          " projects are building"
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
        @logger.info "Blocking builds of '#{job_name}' when upstream" +
          " projects are building"
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
        @logger.info "Unblocking builds of '#{job_name}' when upstream" +
          " projects are building"
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
        @logger.info "Setting the concurrent build execution option of" +
          " '#{job_name}' to #{option}"
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
        @logger.info "Obtaining the build params of '#{job_name}'"
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

      # Add downstream projects to a specific job given the job name,
      # projects to be added as downstream projects, and the threshold
      #
      # @param [String] job_name
      # @param [String] downstream_projects
      # @param [String] threshold - failure, success, or unstable
      # @param [Boolean] overwrite - true or false
      #
      # @return [String] response_code return code from HTTP POST
      #
      def add_downstream_projects(job_name,
                                  downstream_projects,
                                  threshold, overwrite = false)
        @logger.info "Adding #{downstream_projects.inspect} as downstream" +
          " projects for '#{job_name}' with the threshold of '#{threshold}'" +
          " and overwrite option of '#{overwrite}'"
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
        @logger.info "Removing the downstream projects of '#{job_name}'"
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
        @logger.info "Restricting '#{job_name}' to '#{node_name}' node"
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
        @logger.info "Unchaining jobs: #{job_names.inspect}"
        job_names.each { |job| remove_downstream_projects(job) }
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

        @logger.info "Chaining jobs: #{job_names.inspect}" +
          " with threshold of '#{threshold}' and criteria as '#{criteria}'" +
          " with #{parallel} number of parallel jobs"
        filtered_job_names = []
        if criteria.include?("all") || criteria.empty?
          filtered_job_names = job_names
        else
          job_names.each do |job|
            filtered_job_names << job if criteria.include?(
              @client.job.get_current_build_status(job)
            )
          end
        end

        filtered_job_names.each_with_index do |job_name, index|
          break if index >= (filtered_job_names.length - parallel)
          @client.job.add_downstream_projects(
            job_name, filtered_job_names[index + parallel], threshold, true
          )
        end
        if parallel > filtered_job_names.length
          parallel = filtered_job_names.length
        end
        filtered_job_names[0..parallel-1]
      end

      private

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

      # This private method builds portion of XML that adds subversion SCM
      # to a Job
      #
      # @param [Hash] params parameters to be used for building XML
      # @param [XML] xml Nokogiri XML object
      #
      def scm_subversion(params, xml)
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
      end

      # This private method builds portion of XML that adds CVS SCM to a Job
      #
      # @param [Hash] params parameters to be used for building XML
      # @param [XML] xml Nokogiri XML object
      #
      def scm_cvs(params, xml)
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
      end

      # This private method adds portion of XML that adds Git SCM to a Job
      #
      # @param [Hash] params parameters to be used for building XML
      # @param [XML] xml Nokogiri XML object
      #
      def scm_git(params, xml)
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
      end

      # Method for creating portion of xml that builds Skype notification
      # Use this option only when you have the Skype plugin installed and
      # everything is set up properly
      #
      # @param [Hash] params Parameters for adding skype notificaiton. For the
      # options in this params Hash refer to create_freestyle
      # @param [XML] xml Main xml to attach the skype portion.
      #
      def skype_notification(params, xml)
        params[:skype_strategy] = case params[:skype_strategy]
        when "all"
          "ALL"
        when "failure"
          "ANY_FAILURE"
        when "failure_and_fixed"
          "FAILURE_AND_FIXED"
        when "change"
          "STATECHANGE_ONLY"
        else
          "STATECHANGE_ONLY"
        end

        params[:skype_notify_on_build_start] = false if params[:skype_notify_on_build_start].nil?
        params[:skype_notify_suspects] = false if params[:skype_notify_suspects].nil?
        params[:skype_notify_culprits] = false if params[:skype_notify_culprits].nil?
        params[:skype_notify_fixers] = false if params[:skype_notify_fixers].nil?
        params[:skype_notify_upstream_committers] = false if params[:skype_notify_upstream_committers].nil?

        targets = params[:skype_targets].split(/\s+/)
        xml.send("hudson.plugins.skype.im.transport.SkypePublisher") {
          xml.targets {
            targets.each { |target|
              if target =~ /^\*/
                # Group Chat
                xml.send("hudson.plugins.im.GroupChatIMMessageTarget") {
                  # Skipe the first * character
                  xml.value target[1..-1]
                  xml.notificationOnly false
                }
              else
                # Individual message
                xml.send("hudson.plugins.im.DefaultIMMessageTarget") {
                  xml.value target
                }
              end
            }
          }
          xml.strategy "#{params[:skype_strategy]}"
          xml.notifyOnBuildStart params[:skype_notify_on_build_start]
          xml.notifySuspects params[:skype_notify_suspects]
          xml.notifyCulprits params[:skype_notify_culprits]
          xml.notifyFixers params[:skype_notify_fixers]
          xml.notifyUpstreamCommitters params[:skype_notify_upstream_committers]
          notification_class = case params[:skype_message]
          when "just_summary"
            "hudson.plugins.im.build_notify.SummaryOnlyBuildToChatNotifier"
          when "summary_and_scm_changes"
            "hudson.plugins.im.build_notify.DefaultBuildToChatNotifier"
          when "summary_and_build_parameters"
            "hudson.plugins.im.build_notify.BuildParametersBuildToChatNotifier"
          when "summary_scm_changes_and_failed_tests"
            "hudson.plugins.im.build_notify.PrintFailingTestsBuildToChatNotifier"
          else
            "hudson.plugins.im.build_notify.DefaultBuildToChatNotifier"
          end
          xml.buildToChatNotifier(:class => notification_class)
          xml.matrixMultiplier "ONLY_CONFIGURATIONS"
        }
      end

      # This private method builds portion of XML that adds notification email
      # to a Job.
      #
      # @param [Hash] params parameters to be used for building XML
      # @param [XML] xml Nokogiri XML object
      #
      def notification_email(params, xml)
        if params[:notification_email]
          xml.send("hudson.tasks.Mailer") {
            xml.recipients "#{params[:notification_email]}"
            xml.dontNotifyEveryUnstableBuild(
              "#{params[:notification_email_for_every_unstable]}")
            xml.sendToIndividuals(
              "#{params[:notification_email_send_to_individuals]}")
          }
        end
      end

      # This private method builds portion of XML that adds child projects
      # to a Job.
      #
      # @param [Hash] params parameters to be used for building XML
      # @param [XML] xml Nokogiri XML object
      #
      def child_projects(params, xml)
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
    end
  end
end
