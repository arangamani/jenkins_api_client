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

require 'jenkins_api_client/urihelper'

module JenkinsApi
  class Client
    # This class communicates with the Jenkins "/job" API to obtain details
    # about jobs, creating, deleting, building, and various other operations.
    #
    class Job
      include JenkinsApi::UriHelper

      # Version that jenkins started to include queued build info in build response
      JENKINS_QUEUE_ID_SUPPORT_VERSION = '1.519'

      attr_reader :plugin_collection

      # Initialize the Job object and store the reference to Client object
      #
      # @param client [Client] the client object
      #
      # @return [Job] the job object
      #
      def initialize(client, *plugin_settings)
        @client = client
        @logger = @client.logger
        @plugin_collection = JenkinsApi::Client::PluginSettings::Collection.new(*plugin_settings)
      end

      # Add a plugin to be included in job's xml configureation
      #
      # @param plugin [Jenkins::Api::Client::PluginSettings::Base]
      #
      # @return [JenkinsApi::Client::PluginSettings::Collection] the job object
      def add_plugin(plugin)
        plugin_collection.add(plugin)
      end

      # Remove a plugin to be included in job's xml configureation
      #
      # @param plugin [Jenkins::Api::Client::PluginSettings::Base]
      #
      # @return [JenkinsApi::Client::PluginSettings::Collection] the job object
      def remove_plugin(plugin)
        plugin_collection.remove(plugin)
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
        if exists?(job_name)
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
        @client.post_config("/createItem?name=#{form_encode job_name}", xml)
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
      # @option params [String] :name
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
      # @option params [String] :scm_credentials_id
      #   the id of the credentials to use for authenticating with scm. Only for "git"
      # @option params [String] :scm_git_tool
      #   the git executable. Defaults to "Default"; only for "git"
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
      # @param params [Hash] parameters to update a freestyle project
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
            #buildlogs related stuff
            if params[:discard_old_builds]
              xml.logRotator(:class => 'hudson.tasks.LogRotator') do
                xml.daysToKeep params[:discard_old_builds][:daysToKeep] || -1
                xml.numToKeep params[:discard_old_builds][:numToKeep] || -1
                xml.artifactDaysToKeep params[:discard_old_builds][:artifactDaysToKeep] || -1
                xml.artifactNumToKeep params[:discard_old_builds][:artifactNumToKeep] || -1
              end
            end

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
            xml.triggers.vector do
              if params[:timer]
                xml.send("hudson.triggers.TimerTrigger") do
                  xml.spec params[:timer]
                end
              end

              if params[:scm_trigger]
                xml.send("hudson.triggers.SCMTrigger") do
                  xml.spec params[:scm_trigger]
                  xml.ignorePostCommitHooks params.fetch(:ignore_post_commit_hooks) { false }
                end
              end
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
              artifact_archiver(params[:artifact_archiver], xml)
            end
            xml.buildWrappers
          end
        end

        xml_doc = Nokogiri::XML(builder.to_xml)
        plugin_collection.configure(xml_doc).to_xml
      end


      # Adding email notification to a job
      #
      # @param [Hash] params parameters to add email notification
      #
      # @option params [String] :name Name of the job
      # @option params [String] :notification_email Email address to send
      # @option params [Boolean] :notification_email_for_every_unstable
      #   Send email notification email for every unstable build
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

      # Configure post-build step to archive artifacts
      #
      # @param artifact_params [Hash] parameters controlling how artifacts are archived
      #
      # @option artifact_params [String] :artifact_files
      #   pattern or names of files to archive
      # @option artifact_params [String] :excludes
      #   pattern or names of files to exclude
      # @option artifact_params [Boolean] :fingerprint (false)
      #   fingerprint the archives
      # @option artifact_params [Boolean] :allow_empty_archive (false)
      #   whether to allow empty archives
      # @option artifact_params [Boolean] :only_if_successful (false)
      #   only archive if successful
      # @option artifact_params [Boolean] :default_excludes (false)
      #   exclude defaults automatically
      #
      # @return [Nokogiri::XML::Builder]
      #
      def artifact_archiver(artifact_params, xml)
        return xml if artifact_params.nil?

        xml.send('hudson.tasks.ArtifactArchiver') do |x|
          x.artifacts artifact_params.fetch(:artifact_files) { '' }
          x.excludes artifact_params.fetch(:excludes) { '' }
          x.fingerprint artifact_params.fetch(:fingerprint) { false }
          x.allowEmptyArchive artifact_params.fetch(:allow_empty_archive) { false }
          x.onlyIfSuccessful artifact_params.fetch(:only_if_successful) { false }
          x.defaultExcludes artifact_params.fetch(:default_excludes) { false }
        end

        xml
      end

      # Rename a job given the old name and new name
      #
      # @param [String] old_job Name of the old job
      # @param [String] new_job Name of the new job.
      #
      def rename(old_job, new_job)
        @logger.info "Renaming job '#{old_job}' to '#{new_job}'"
        @client.api_post_request("/job/#{path_encode old_job}/doRename?newName=#{form_encode new_job}")
      end

      # Delete a job given the name
      #
      # @param job_name [String] the name of the job to delete
      #
      # @return [String] the response from the HTTP POST request
      #
      def delete(job_name)
        @logger.info "Deleting job '#{job_name}'"
        @client.api_post_request("/job/#{path_encode job_name}/doDelete")
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
      # @param job_name [String] the name of the job to wipe out the workspace
      #
      # @return [String] response from the HTTP POST request
      #
      def wipe_out_workspace(job_name)
        @logger.info "Wiping out the workspace of job '#{job_name}'"
        @client.api_post_request("/job/#{path_encode job_name}/doWipeOutWorkspace")
      end

      # Stops a running build of a job
      # This method will stop the current/most recent build if no build number
      # is specified. The build will be stopped only if it was
      # in 'running' state.
      #
      # @param job_name [String] the name of the job to stop the build
      # @param build_number [Number] the build number to stop
      #
      def stop_build(job_name, build_number = 0)
        build_number = get_current_build_number(job_name) if build_number == 0
        raise "No builds for #{job_name}" unless build_number
        @logger.info "Stopping job '#{job_name}' Build ##{build_number}"
        # Check and see if the build is running
        is_building = @client.api_get_request(
          "/job/#{path_encode job_name}/#{build_number}"
        )["building"]
        if is_building
          @client.api_post_request("/job/#{path_encode job_name}/#{build_number}/stop")
        end
      end
      alias_method :stop, :stop_build
      alias_method :abort, :stop_build

      # Re-create the same job
      # This is a hack to clear any existing builds
      #
      # @param job_name [String] the name of the job to recreate
      #
      # @return [String] the response from the HTTP POST request
      #
      def recreate(job_name)
        @logger.info "Recreating job '#{job_name}'"
        job_xml = get_config(job_name)
        delete(job_name)
        create(job_name, job_xml)
      end

      # Copy a job
      #
      # @param from_job_name [String] the name of the job to copy from
      # @param to_job_name [String] the name of the job to copy to
      #
      # @return [String] the response from the HTTP POST request
      #
      def copy(from_job_name, to_job_name=nil)
        to_job_name = "copy_of_#{from_job_name}" if to_job_name.nil?
        @logger.info "Copying job '#{from_job_name}' to '#{to_job_name}'"
        @client.api_post_request(
          "/createItem?name=#{path_encode to_job_name}&mode=copy&from=#{path_encode from_job_name}"
        )
      end

      # Get progressive console output from Jenkins server for a job
      #
      # @param [String] job_name Name of the Jenkins job
      # @param [Number] build_num Specific build number to obtain the
      #   console output from. Default is the recent build
      # @param [Number] start start offset to get only a portion of the text
      # @param [String] mode Mode of text output. 'text' or 'html'
      #
      # @return [Hash] response
      #   * +output+ console output of the job
      #   * +size+ size of the text. This can be used as 'start' for the
      #     next call to get progressive output
      #   * +more+ more data available for the job. 'true' if available
      #     and nil otherwise
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
        get_msg = "/job/#{path_encode job_name}/#{build_num}/logText/progressive#{mode}?"
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
      # @return [Array<String>] the names of all jobs in jenkins
      #
      def list_all
        response_json = @client.api_get_request("", "tree=jobs[name]")["jobs"]
        response_json.map { |job| job["name"] }.sort
      end

      # Checks if the given job exists in Jenkins
      #
      # @param job_name [String] the name of the job to check
      #
      # @return [Boolean] whether the job exists in jenkins or not
      #
      def exists?(job_name)
        list(job_name).include?(job_name)
      end

      # List all Jobs matching the given status
      # You can optionally pass in jobs list to filter the status from
      #
      # @param status [String] the job status to filter
      # @param jobs [Array<String>] if specified this array will be used for
      #   filtering by the status otherwise the filtering will be done using
      #   all jobs available in jenkins
      #
      # @return [Array<String>] filtered jobs
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
      # @param filter [String] a regular expression or a string to filter jobs
      # @param ignorecase [Boolean] whether to ignore case or not
      #
      # @return [Array<String>] jobs matching the given pattern
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
      # @return [Array<Hash>] the details of all jobs in jenkins
      #
      def list_all_with_details
        @logger.info "Obtaining the details of all jobs"
        response_json = @client.api_get_request("")
        response_json["jobs"]
      end

      # List details of a specific job
      #
      # @param job_name [String] the name of the job to obtain the details from
      #
      # @return [Hash] the details of the specified job
      #
      def list_details(job_name)
        @logger.info "Obtaining the details of '#{job_name}'"
        @client.api_get_request("/job/#{path_encode job_name}")
      end

      # List upstream projects of a specific job
      #
      # @param job_name [String] the name of the job to obtain upstream
      #  projects for
      #
      def get_upstream_projects(job_name)
        @logger.info "Obtaining the upstream projects of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{path_encode job_name}")
        response_json["upstreamProjects"]
      end

      # List downstream projects of a specific job
      #
      # @param job_name [String] the name of the job to obtain downstream
      #   projects for
      #
      def get_downstream_projects(job_name)
        @logger.info "Obtaining the down stream projects of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{path_encode job_name}")
        response_json["downstreamProjects"]
      end

      # Obtain build details of a specific job
      #
      # @param [String] job_name
      #
      def get_builds(job_name, options = {})
        @logger.info "Obtaining the build details of '#{job_name}'"
        url = "/job/#{path_encode job_name}"

        tree = options[:tree] || nil
        response_json = @client.api_get_request url, tree_string(tree)
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
        when "disabled"
          "disabled"
        else
          "invalid"
        end
      end

      # Determine if the build is queued
      #
      # @param [String] job_name
      #
      # @return [Integer] build number if queued, or [Boolean] false if not queued
      #
      def queued?(job_name)
        queue_result = @client.api_get_request("/job/#{path_encode job_name}")['inQueue']
        if queue_result
          return @client.api_get_request("/job/#{path_encode job_name}")['nextBuildNumber']
        else
          return queue_result
        end
      end

      # Obtain the current build status of the job
      # By default Jenkins returns the color of the job status icon
      # This function translates the color into a meaningful status
      #
      # @param [String] job_name
      #
      # @return [String] status current status of the given job
      #
      def get_current_build_status(job_name)
        @logger.info "Obtaining the current build status of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{path_encode job_name}")
        color_to_status(response_json["color"])
      end
      alias_method :status, :get_current_build_status

      # Obtain the current build number of the given job
      # This function returns nil if there were no builds for the given job.
      #
      # @param [String] job_name
      #
      # @return [Integer] current build number of the given job
      #
      def get_current_build_number(job_name)
        @logger.info "Obtaining the current build number of '#{job_name}'"
        @client.api_get_request("/job/#{path_encode job_name}")['nextBuildNumber'].to_i - 1
      end
      alias_method :build_number, :get_current_build_number

      # Build a Jenkins job, optionally waiting for build to start and
      # returning the build number.
      # Adds support for new/old Jenkins servers where build_queue id may
      # not be available. Also adds support for periodic callbacks, and
      # optional cancellation of queued_job if not started within allowable
      # time window (if build_queue option available)
      #
      #   Notes:
      #     'opts' may be a 'true' or 'false' value to maintain
      #       compatibility with old method signature, where true indicates
      #     'return_build_number'. In this case, true is translated to:
      #       { 'build_start_timeout' => @client_timeout }
      #       which simulates earlier behavior.
      #
      #   progress_proc
      #     Optional proc that is called periodically while waiting for
      #     build to start.
      #     Initial call (with poll_count == 0) indicates build has been
      #     requested, and that polling is starting.
      #     Final call will indicate one of build_started or cancelled.
      #     params:
      #       max_wait [Integer] Same as opts['build_start_timeout']
      #       current_wait [Integer]
      #       poll_count [Integer] How many times has queue been polled
      #
      #   completion_proc
      #     Optional proc that is called <just before> the 'build' method
      #     exits.
      #     params:
      #       build_number [Integer]  Present if build started or nil
      #       build_cancelled [Boolean]  True if build timed out and was
      #         successfully removed from build-queue
      #
      # @param [String] job_name the name of the job
      # @param [Hash]   params   the parameters for parameterized build
      # @param [Hash]   opts     options for this method
      #  * +build_start_timeout+ [Integer] How long to wait for queued
      #    build to start before giving up. Default: 0/nil
      #  * +cancel_on_build_start_timeout+ [Boolean] Should an attempt be
      #    made to cancel the queued build if it hasn't started within
      #    'build_start_timeout' seconds? This only works on newer versions
      #    of Jenkins where JobQueue is exposed in build post response.
      #    Default: false
      #  * +poll_interval+ [Integer] How often should we check with CI
      #    Server while waiting for start. Default: 2 (seconds)
      #  * +progress_proc+ [Proc] A proc that will receive progress notitications. Default: nil
      #  * +completion_proc+ [Proc] A proc that is called <just before>
      #    this method (build) exits.  Default: nil
      #
      # @return [Integer] build number, or nil if not started (IF TIMEOUT SPECIFIED)
      # @return [String] HTTP response code (per prev. behavior) (NO TIMEOUT SPECIFIED)
      #
      def build(job_name, params={}, opts = {})
        if opts.nil? || opts.is_a?(FalseClass)
          opts = {}
        elsif opts.is_a?(TrueClass)
          opts = { 'build_start_timeout' => @client_timeout }
        end

        opts['job_name'] = job_name

        msg = "Building job '#{job_name}'"
        msg << " with parameters: #{params.inspect}" unless params.empty?
        @logger.info msg

        if (opts['build_start_timeout'] || 0) > 0
          # Best-guess build-id
          # This is only used if we go the old-way below... but we can use this number to detect if multiple
          # builds were queued
          current_build_id = get_current_build_number(job_name)
          expected_build_id = current_build_id > 0 ? current_build_id + 1 : 1
        end

        if (params.nil? or params.empty?)
          response = @client.api_post_request("/job/#{path_encode job_name}/build",
            {},
            true)
        else
          response = @client.api_post_request("/job/#{path_encode job_name}/buildWithParameters",
            params,
            true)
        end

        if (opts['build_start_timeout'] || 0) > 0
          if @client.compare_versions(@client.get_jenkins_version, JENKINS_QUEUE_ID_SUPPORT_VERSION) >= 0
            return get_build_id_from_queue(response, expected_build_id, opts)
          else
            return get_build_id_the_old_way(expected_build_id, opts)
          end
        else
          return response.code
        end
      end

      def get_build_id_from_queue(response, expected_build_id, opts)
        # If we get this far the API hasn't detected an error response (it would raise Exception)
        # So no need to check response code
        # Obtain the queue ID from the location
        # header and wait till the build is moved to one of the executors and a
        # build number is assigned
        build_start_timeout = opts['build_start_timeout']
        poll_interval = opts['poll_interval'] || 2
        poll_interval = 1 if poll_interval < 1
        progress_proc = opts['progress_proc']
        completion_proc = opts['completion_proc']
        job_name = opts['job_name']

        if response["location"]
          task_id_match = response["location"].match(/\/item\/(\d*)\//)
          task_id = task_id_match.nil? ? nil : task_id_match[1]
          unless task_id.nil?
            @logger.info "Job queued for #{job_name}, will wait up to #{build_start_timeout} seconds for build to start..."

            # Let progress proc know we've queued the build
            progress_proc.call(build_start_timeout, 0, 0) if progress_proc

            # Wait for the build to start
            begin
              start = Time.now.to_i
              Timeout::timeout(build_start_timeout) do
                started = false
                attempts = 0

                while !started
                  # Don't really care about the response... if we get thru here, then it must have worked.
                  # Jenkins will return 404's until the job starts
                  queue_item = @client.queue.get_item_by_id(task_id)

                  if queue_item['executable'].nil?
                    # Job not started yet
                    attempts += 1

                    progress_proc.call(build_start_timeout, (Time.now.to_i - start), attempts) if progress_proc
                    # Every 5 attempts (~10 seconds)
                    @logger.info "Still waiting..." if attempts % 5 == 0

                    sleep poll_interval
                  else
                    build_number = queue_item['executable']['number']
                    completion_proc.call(build_number, false) if completion_proc

                    return build_number
                  end
                end
              end
            rescue Timeout::Error
              # Well, we waited - and the job never started building
              # Attempt to kill off queued job (if flag set)
              if opts['cancel_on_build_start_timeout']
                @logger.info "Job for '#{job_name}' did not start in a timely manner, attempting to cancel pending build..."

                begin
                  @client.api_post_request("/queue/cancelItem?id=#{task_id}")
                  @logger.info "Job cancelled"
                  completion_proc.call(nil, true) if completion_proc
                rescue JenkinsApi::Exceptions::ApiException => e
                  completion_proc.call(nil, false) if completion_proc
                  @logger.warn "Error while attempting to cancel pending job for '#{job_name}'. #{e.class} #{e}"
                  raise
                end
              else
                @logger.info "Jenkins build for '#{job_name}' failed to start in a timely manner"
                completion_proc.call(nil, false) if completion_proc
              end

              # Old version used to throw timeout error, so we should let that go thru now
              raise
            rescue JenkinsApi::Exceptions::ApiException => e
              # Jenkins Api threw an error at us
              completion_proc.call(nil, false) if completion_proc
              @logger.warn "Problem while waiting for '#{job_name}' build to start.  #{e.class} #{e}"
              raise
            end
          else
            @logger.warn "Jenkins did not return a queue_id for '#{job_name}' build (location: #{response['location']})"
            return get_build_id_the_old_way(expected_build_id, opts)
          end
        else
          @logger.warn "Jenkins did not return a location header for '#{job_name}' build"
          return get_build_id_the_old_way(expected_build_id, opts)
        end
      end
      private :get_build_id_from_queue

      def get_build_id_the_old_way(expected_build_id, opts)
        # Try to wait until the build starts so we can mimic queue
        # Wait for the build to start
        build_start_timeout = opts['build_start_timeout']
        poll_interval = opts['poll_interval'] || 2
        poll_interval = 1 if poll_interval < 1
        progress_proc = opts['progress_proc']
        completion_proc = opts['completion_proc']
        job_name = opts['job_name']

        @logger.info "Build requested for '#{job_name}', will wait up to #{build_start_timeout} seconds for build to start..."

        # Let progress proc know we've queued the build
        progress_proc.call(build_start_timeout, 0, 0) if progress_proc

        begin
          start = Time.now.to_i
          Timeout::timeout(build_start_timeout) do
            attempts = 0

            while true
              attempts += 1

              # Don't really care about the response... if we get thru here, then it must have worked.
              # Jenkins will return 404's until the job starts
              begin
                get_build_details(job_name, expected_build_id)
                completion_proc.call(expected_build_id, false) if completion_proc

                return expected_build_id
              rescue JenkinsApi::Exceptions::NotFound => e
                progress_proc.call(build_start_timeout, (Time.now.to_i - start), attempts) if progress_proc

                # Every 5 attempts (~10 seconds)
                @logger.info "Still waiting..." if attempts % 5 == 0

                sleep poll_interval
              end
            end
          end
        rescue Timeout::Error
          # Well, we waited - and the job never started building
          # Now we need to raise an exception so that the build can be officially failed
          completion_proc.call(nil, false) if completion_proc
          @logger.info "Jenkins '#{job_name}' build failed to start in a timely manner"

          # Old version used to propagate timeout error
          raise
        rescue JenkinsApi::Exceptions::ApiException => e
          completion_proc.call(nil, false) if completion_proc
          # Jenkins Api threw an error at us
          @logger.warn "Problem while waiting for '#{job_name}' build ##{expected_build_id} to start.  #{e.class} #{e}"
          raise
        end
      end
      private :get_build_id_the_old_way

      # Programatically schedule SCM polling for the specified job
      #
      # @param job_name [String] the name of the job
      #
      # @return [String] the response code from the HTTP post request
      #
      def poll(job_name)
        @logger.info "Polling SCM changes for job '#{job_name}'"
        @client.api_post_request("/job/#{job_name}/polling")
      end

      # Enable a job given the name of the job
      #
      # @param [String] job_name
      #
      def enable(job_name)
        @logger.info "Enabling job '#{job_name}'"
        @client.api_post_request("/job/#{path_encode job_name}/enable")
      end

      # Disable a job given the name of the job
      #
      # @param [String] job_name
      #
      def disable(job_name)
        @logger.info "Disabling job '#{job_name}'"
        @client.api_post_request("/job/#{path_encode job_name}/disable")
      end

      # Obtain the configuration stored in config.xml of a specific job
      #
      # @param [String] job_name
      #
      # @return [String] XML Config.xml of the job
      #
      def get_config(job_name)
        @logger.info "Obtaining the config.xml of '#{job_name}'"
        @client.get_config("/job/#{path_encode job_name}")
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
        @client.post_config("/job/#{path_encode job_name}/config.xml", xml)
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
        @client.api_get_request("/job/#{path_encode job_name}/#{build_num}/testReport")
      rescue Exceptions::NotFound
        # Not found is acceptable, as not all builds will have test results
        # and this is what jenkins throws at us in that case
        nil
      end

      # Obtain the plugin results for a specific build of a job
      #
      # @param [String] job_name
      # @param [Number] build_num
      # @param [String] plugin_name
      #
      def get_plugin_results(job_name, build_num, plugin_name)
        build_num = get_current_build_number(job_name) if build_num == 0
        @logger.info "Obtaining the '#{plugin_name}' plugin results of '#{job_name}'" +
          " Build ##{build_num}"
        @client.api_get_request("/job/#{path_encode job_name}/#{build_num}/#{plugin_name}Result")
      rescue Exceptions::NotFound
        # Not found is acceptable, as not all builds will have plugin results
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

        @client.api_get_request("/job/#{path_encode job_name}/#{build_num}/")
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

      # Add upstream projects to a specific job given the job name,
      # projects to be added as upstream projects, and the threshold
      #
      # @param [String] job_name
      # @param [String] upstream_projects - separated with comma
      # @param [String] threshold - failure, success, or unstable
      # @param [Boolean] overwrite - true or false
      #
      # @return [String] response_code return code from HTTP POST
      #
      def add_upstream_projects(job_name,
                                upstream_projects,
                                threshold, overwrite = false)
        @logger.info "Adding #{upstream_projects.inspect} as upstream" +
                         " projects for '#{job_name}' with the threshold of '#{threshold}'" +
                         " and overwrite option of '#{overwrite}'"
        name, ord, col = get_threshold_params(threshold)
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        upstream_projects_node = n_xml.xpath("//upstreamProjects").first
        if upstream_projects_node
          if overwrite
            upstream_projects_node.content = "#{upstream_projects}"
          else
            to_replace = upstream_projects_node.content +
                ", #{upstream_projects}"
            upstream_projects_node.content = to_replace
          end
        else
          triggers_node = n_xml.xpath("//triggers").first
          reverse_build_trigger_node = triggers_node.add_child(
              "<jenkins.triggers.ReverseBuildTrigger/>"
          )
          reverse_build_trigger_node.first.add_child(
              "<spec/>"
          )
          reverse_build_trigger_node.first.add_child(
              "<upstreamProjects>#{upstream_projects}</upstreamProjects>"
          )
          threshold_node = reverse_build_trigger_node.first.add_child(
              "<threshold/>"
          )
          threshold_node.first.add_child(
              "<name>#{name}</name><ordinal>#{ord}</ordinal><color>#{col}</color>"
          )
        end
        xml_modified = n_xml.to_xml
        post_config(job_name, xml_modified)
      end

      # Remove all upstream projects of a specific job
      #
      # @param [String] job_name
      #
      # @return [String] response_code return code from HTTP POST
      #
      def remove_upstream_projects(job_name)
        @logger.info "Removing the upstream projects of '#{job_name}'"
        xml = get_config(job_name)
        n_xml = Nokogiri::XML(xml)
        n_xml.search("//jenkins.triggers.ReverseBuildTrigger").remove
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

      # Get a list of promoted builds for given job
      #
      # @param  [String] job_name
      # @return [Hash]   Hash map of promitions and the promoted builds. Promotions that didn't took place yet
      #                  return nil
      def get_promotions(job_name)
        result = {}

        @logger.info "Obtaining the promotions of '#{job_name}'"
        response_json = @client.api_get_request("/job/#{job_name}/promotion")

        response_json["processes"].each do |promotion|
          @logger.info "Getting promotion details of '#{promotion['name']}'"

          if promotion['color'] == 'notbuilt'
            result[promotion['name']] = nil
          else
            promo_json = @client.api_get_request("/job/#{job_name}/promotion/latest/#{promotion['name']}")
            result[promotion['name']] = promo_json['target']['number']
          end
        end

        result
      end


      # Create a new promotion process
      #
      # This must be called before set/get promote config can be used on a process
      #
      # Must be called after updating the job's config
      # @param  [String] job_name
      # @param  [String] process The process name
      # @return [String] Process config
      def init_promote_process(job_name, process, config)
        @logger.info "Creating new process #{process} for job #{job_name}"
        @client.post_config("/job/#{job_name}/promotion/createProcess?name=#{process}", config)
      end


      # Get a job's promotion config
      #
      # @param  [String] job_name
      # @param  [String] process The process name
      # @return [String] Promote config
      def get_promote_config(job_name, process)
        @logger.info "Getting promote config for job '#{job_name}' process '#{process}'"
        @client.get_config("/job/#{job_name}/promotion/process/#{process}/config.xml")
      end

      # Set a job's promotion config
      #
      # @param  [String] job_name
      # @param  [String] process The process name
      # @param  [String] Job config
      # @return nil
      def set_promote_config(job_name, process, config)
        @logger.info "Setting promote config for job '#{job_name}' process '#{process}' to #{config}"
        @client.post_config("/job/#{job_name}/promotion/process/#{process}/config.xml", config)
      end

      # Delete a job's promotion config
      #
      # @param [String] job_name
      # @param [String] process The process name
      # @return nil
      def delete_promote_config(job_name, process)
        @logger.info "Deleting promote config for job '#{job_name}' process '#{process}'"
        @client.post_config("/job/#{job_name}/promotion/process/#{process}/doDelete")
      end

      #A Method to find artifacts path from the Current Build
      #
      # @param [String] job_name
      # @param [Integer] build_number
      #   defaults to latest build
      #
      def find_artifact(job_name, build_number = 0)
        find_artifacts(job_name, build_number).first
      end

      #A Method to check artifact exists path from the Current Build
      #
      # @param [String] job_name
      # @param [Integer] build_number
      #   defaults to latest build
      #
      def artifact_exists?(job_name, build_number = 0)
        begin
          artifact_path(job_name: job_name, build_number: build_number)

          return true
        rescue Exception => e
          return false
        end
      end

      # Find the artifacts for build_number of job_name, defaulting to current job
      #
      # @param [String] job_name
      # @param [Integer] build_number Optional build number
      # @return [String, Hash] JSON response from Jenkins
      #
      def find_artifacts(job_name, build_number = nil)
        response_json       = get_build_details(job_name, build_number)
        artifact_path(build_details: response_json).map do |p|
          path_encode("#{response_json['url']}artifact/#{p['relativePath']}")
        end
      end

      # Find the artifacts for the current job
      #
      # @param [String] job_name
      # @return [String, Hash] JSON response from Jenkins
      #
      def find_latest_artifacts(job_name)
        find_artifacts(job_name)
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
              xml.credentialsId "#{params[:scm_credentials_id]}"
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
          xml.gitTool params.fetch(:scm_git_tool) { "Default" }
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

      def tree_string tree_value
        return nil unless tree_value
        "tree=#{tree_value}"
      end

      # This private method gets the artifact path or throws an exception
      #
      # @param [Hash] job_name, build_number or build_details object
      #
      def artifact_path(params)
        job_name      = params[:job_name]
        build_number  = params[:build_number] || 0
        build_details = params[:build_details]

        build_details = get_build_details(job_name, build_number) if build_details.nil?
        artifacts     = build_details['artifacts']
        artifact_paths = []

        if artifacts && artifacts.any?
          artifact_paths = artifacts.find_all{ |a| a.key?('relativePath') }
        end

        if artifact_paths.empty?
          raise "No artifacts found."
        end
        artifact_paths
      end
    end
  end
end
