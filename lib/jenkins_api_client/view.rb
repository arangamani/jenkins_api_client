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
    # This class communicates with Jenkins "/view" API and used to create,
    # delete, update, and various other operations permitted on the Jenkins
    # API.
    #
    class View
      include JenkinsApi::UriHelper

      # Initializes a new view object
      #
      # @param client [Client] the client object
      #
      # @return [View] the client object
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
      end

      # Return a string representation of the object
      #
      def to_s
        "#<JenkinsApi::Client::View>"
      end

      # Creates a new empty view of the given type
      #
      # @param [String] view_name Name of the view to be created
      # @param [String] type Type of view to be created. Valid options:
      # listview, myview. Default: listview
      #
      def create(view_name, type = "listview")
        @logger.info "Creating a view '#{view_name}' of type '#{type}'"
        mode = case type
        when "listview"
          "hudson.model.ListView"
        when "myview"
          "hudson.model.MyView"
        else
          raise "Type #{type} is not supported by Jenkins."
        end
        initial_post_params = {
          "name" => view_name,
          "mode" => mode,
          "json" => {
            "name" => view_name,
            "mode" => mode
          }.to_json
        }
        @client.api_post_request("/createView", initial_post_params)
      end

      # Creates a listview by accepting the given parameters hash
      #
      # @param [Hash] params options to create the new view
      # @option params [String] :name Name of the view
      # @option params [String] :description Description of the view
      # @option params [String] :status_filter Filter jobs based on the status.
      #         Valid options: all_selected_jobs, enabled_jobs_only,
      #         disabled_jobs_only. Default: all_selected_jobs
      # @option params [Boolean] :filter_queue true or false
      # @option params [Boolean] :filter_executors true or false
      # @option params [String] :regex Regular expression to filter jobs that
      #         are to be added to the view
      #
      # @raise [ArgumentError] if the required parameter +:name+ is not
      #   specified
      #
      def create_list_view(params)
        # Name is a required parameter. Raise an error if not specified
        raise ArgumentError, "Name is required for creating view" \
          unless params.is_a?(Hash) && params[:name]
        create(params[:name], "listview")
        @logger.debug "Creating a list view with params: #{params.inspect}"
        status_filter = case params[:status_filter]
        when "all_selected_jobs"
          ""
        when "enabled_jobs_only"
          "1"
        when "disabled_jobs_only"
          "2"
        else
          ""
        end
        post_params = {
          "name" => params[:name],
          "mode" => "hudson.model.ListView",
          "description" => params[:description],
          "statusFilter" => status_filter,
          "json" => {
            "name" => params[:name],
            "description" => params[:description],
            "mode" => "hudson.model.ListView",
            "statusFilter" => "",
            "columns" => [
              {
                "stapler-class" => "hudson.views.StatusColumn",
                "kind"=> "hudson.views.StatusColumn"
              },
              {
                "stapler-class" => "hudson.views.WeatherColumn",
                "kind" => "hudson.views.WeatherColumn"
              },
              {
                "stapler-class" => "hudson.views.JobColumn",
                "kind" => "hudson.views.JobColumn"
              },
              {
                "stapler-class" => "hudson.views.LastSuccessColumn",
                "kind" => "hudson.views.LastSuccessColumn"
              },
              {
                "stapler-class" => "hudson.views.LastFailureColumn",
                "kind" => "hudson.views.LastFailureColumn"
              },
              {
                "stapler-class" => "hudson.views.LastDurationColumn",
                "kind" => "hudson.views.LastDurationColumn"
              },
              {
                "stapler-class" => "hudson.views.BuildButtonColumn",
                "kind" => "hudson.views.BuildButtonColumn"
              }
            ]
          }.to_json
        }
        post_params.merge!("filterQueue" => "on") if params[:filter_queue]
        post_params.merge!("filterExecutors" => "on") if params[:filter_executors]
        post_params.merge!("useincluderegex" => "on",
                           "includeRegex" => params[:regex]) if params[:regex]
        @client.api_post_request("/view/#{path_encode params[:name]}/configSubmit",
                                 post_params)
      end

      # Delete a view
      #
      # @param [String] view_name
      #
      def delete(view_name)
        @logger.info "Deleting view '#{view_name}'"
        @client.api_post_request("/view/#{path_encode view_name}/doDelete")
      end

      # Deletes all views (except the All view) in Jenkins.
      #
      # @note This method deletes all views (except the All view) available
      #       in Jenkins. Please use with caution.
      #
      def delete_all!
        @logger.info "Deleting all views from jenkins"
        list.each { |view| delete(view) unless view == "All"}
      end

      # This method lists all views
      #
      # @param [String] filter a regex to filter view names
      # @param [Bool] ignorecase whether to be case sensitive or not
      #
      def list(filter = "", ignorecase = true)
        @logger.info "Obtaining views based on filter '#{filter}'"
        view_names = []
        response_json = @client.api_get_request("", "tree=views[name]")
        response_json["views"].each { |view|
          if ignorecase
            view_names << view["name"] if view["name"] =~ /#{filter}/i
          else
            view_names << view["name"] if view["name"] =~ /#{filter}/
          end
        }
        view_names
      end

      # Checks if the given view exists in Jenkins
      #
      # @param [String] view_name
      #
      def exists?(view_name)
        list(view_name).include?(view_name)
      end

      # List jobs in a view
      #
      # @param [String] view_name
      #
      # @return [Array] job_names list of jobs in the specified view
      #
      def list_jobs(view_name)
        @logger.info "Obtaining the jobs present in view '#{view_name}'"
        job_names = []
        raise "The view #{view_name} doesn't exists on the server"\
          unless exists?(view_name)
        response_json = @client.api_get_request("/view/#{path_encode view_name}")
        response_json["jobs"].each do |job|
          job_names << job["name"]
        end
        job_names
      end

      # List jobs in view along with their details
      #
      # @param [String] view_name
      #
      # @return [Array<Hash>] the details of jobs in the specified view
      #
      def list_jobs_with_details(view_name)
        @logger.info "Obtaining the jobs present in view '#{view_name}'"
        raise "The view #{view_name} doesn't exists on the server"\
          unless exists?(view_name)
        response_json = @client.api_get_request("/view/#{path_encode view_name}")
        response_json["jobs"]
      end

      # Add a job to view
      #
      # @param [String] view_name
      # @param [String] job_name
      #
      def add_job(view_name, job_name)
        @logger.info "Adding job '#{job_name}' to view '#{view_name}'"
        post_msg = "/view/#{path_encode view_name}/addJobToView?name=#{form_encode job_name}"
        @client.api_post_request(post_msg)
      end

      # Remove a job from view
      #
      # @param [String] view_name
      # @param [String] job_name
      #
      def remove_job(view_name, job_name)
        @logger.info "Removing job '#{job_name}' from view '#{view_name}'"
        post_msg = "/view/#{path_encode view_name}/removeJobFromView?name=#{form_encode job_name}"
        @client.api_post_request(post_msg)
      end

      # List (sub-)views in a view
      #
      # @param [String] view_name
      #
      # @return [Array] view_names list of (sub-)views in the specified view
      #
      def list_views(view_name)
        @logger.info "Obtaining the views present in view '#{view_name}'"
        view_names = []
        raise "The view #{view_name} doesn't exists on the server"\
          unless exists?(view_name)
        response_json = @client.api_get_request("/view/#{path_encode view_name}")
        response_json["views"].each do |view|
          view_names << view["name"]
        end
        view_names
      end

      # List (sub-)views in view along with their details
      #
      # @param [String] view_name
      #
      # @return [Array<Hash>] the details of (sub-)views in the specified view
      #
      def list_views_with_details(view_name)
        @logger.info "Obtaining the views present in view '#{view_name}'"
        raise "The view #{view_name} doesn't exists on the server"\
          unless exists?(view_name)
        response_json = @client.api_get_request("/view/#{path_encode view_name}")
        response_json["views"]
      end

      # Obtain the configuration stored in config.xml of a specific view
      #
      # @param [String] view_name
      #
      def get_config(view_name)
        @logger.info "Obtaining the configuration of view '#{view_name}'"
        @client.get_config("/view/#{path_encode view_name}")
      end

      # Post the configuration of a view given the view name and the config.xml
      #
      # @param [String] view_name
      # @param [String] xml
      #
      def post_config(view_name, xml)
        @logger.info "Posting the configuration of view '#{view_name}'"
        @client.post_config("/view/#{path_encode view_name}/config.xml", xml)
      end

    end
  end
end
