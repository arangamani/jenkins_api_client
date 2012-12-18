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
    class View

      # Initializes a new view object
      #
      # @param [Object] client reference to Client
      #
      def initialize(client)
        @client = client
      end

      def to_s
        "#<JenkinsApi::Client::View>"
      end

      def create(view_name, xml)
        #@client.api_post_request("/createView?name=#{view_name}&mode=hudson.model.ListView&json={\"name\":\"#{view_name}\",\"mode\":\"hudson.model.ListView\"}")
        post_config(view_name, xml)
      end

      def create_with_params(params)
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
          xml.send("hudson.model.View_-2") {
            xml.send("outer-class", :class => "hudson.model.ListView") {
              xml.name "#{params[:name]}"
              xml.filterExecutors "false"
              xml.filterQueue "false"
              xml.properties(:class => "hudson.model.View$PropertyList")
              xml.jobNames(:class => "tree-set") {
                xml.comparator(:class => "hudson.util.CaseInsensitiveComparator")
                if params[:job_names]
                  params[:job_names].each do |job_name|
                    xml.string "#{job_name}"
                  end
                end
              }
              xml.jobFilters
              xml.columns {
                xml.send("hudson.views.StatusColumn")
                xml.send("hudson.views.WeatherColumn")
                xml.send("hudson.views.JobColumn")
                #xml.send("hudson.views.LastSuccessColumn")
                #xml.send("hudson.views.LastFailureColumn")
                #xml.send("hudson.views.LastDurationColumn")
                #xml.send("hudson.views.BuildButtonColumn")
              }
              if params[:include_regex]
                xml.includeRegex "#{params[:include_regex]}"
              end
            }
          }
        }
        puts "#{builder.to_xml}"
        got_xml = get_config(params[:name])
        puts "#{got_xml}"
        create(params[:name], builder.to_xml)
      end

      def delete(view_name)
        @client.api_post_request("/view/#{view_name}/doDelete")
      end

      # This method lists all views
      #
      # @param [String] filter a regex to filter view names
      # @param [Bool] ignorecase whether to be case sensitive or not
      #
      def list(filter = nil, ignorecase = true)
        view_names = []
        response_json = @client.api_get_request("/")
        response_json["views"].each { |view|
          view_names << view["name"] if view["name"] =~ /#{filter}/i
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
      def list_jobs(view_name)
        job_names = []
        response_json = @client.api_get_request("/view/#{view_name}")
        response_json["jobs"].each do |job|
          job_names << job["name"]
        end
        job_names
      end

      # Add a job to view
      #
      # @param [String] view_name
      # @param [String] job_name
      #
      def add_job(view_name, job_name)
        @client.api_post_request("/view/#{view_name}/addJobToView?name=#{job_name}")
      end

      # Remove a job from view
      #
      # @param [String] view_name
      # @param [String] job_name
      #
      def remove_job(view_name, job_name)
        @client.api_post_request("/view/#{view_name}/removeJobFromView?name=#{job_name}")
      end

      def get_config(view_name)
        @client.get_config("/view/#{view_name}")
      end

      def post_config(view_name, xml)
        @client.post_config("/view/#{view_name}/config.xml", xml)
      end

    end
  end
end
