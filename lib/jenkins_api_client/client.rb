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

require 'rubygems'
require 'json'
require 'net/http'
require 'nokogiri'
require 'active_support/core_ext'
require 'active_support/builder'
require 'base64'

module JenkinsApi
  class Client
    attr_accessor :debug, :timeout
    DEFAULT_SERVER_PORT = 8080
    DEFAULT_TIMEOUT = 120
    VALID_PARAMS = [
      "server_ip",
      "server_port",
      "jenkins_path",
      "username",
      "password",
      "password_base64",
      "debug",
      "timeout"
    ].freeze

    # Initialize a Client object with Jenkins CI server credentials
    #
    # @param [Hash] args
    #  * the +:server_ip+ param is the IP address of the Jenkins CI server
    #  * the +:server_port+ param is the port on which the Jenkins listens
    #  * the +:username+ param is the username used for connecting to the server
    #  * the +:password+ param is the password for connecting to the CI server
    #
    def initialize(args)
      args.each do |key, value|
        if value && VALID_PARAMS.include?(key.to_s)
          instance_variable_set("@#{key}", value)
        end
      end if args.is_a? Hash
     raise "Server IP is required to connect to Jenkins" unless @server_ip
     unless @username && (@password || @password_base64)
       raise "Credentials are required to connect to te Jenkins Server"
     end
     @server_port = DEFAULT_SERVER_PORT unless @server_port
     @timeout = DEFAULT_TIMEOUT unless @timeout
     @debug = false unless @debug
     @crumbs_enabled = use_crumbs?
     # Base64 decode inserts a newline character at the end. As a workaround
     # added chomp to remove newline characters. I hope nobody uses newline
     # characters at the end of their passwords :)
     @password = Base64.decode64(@password_base64).chomp if @password_base64
    end

    # This method toggles the debug parameter in run time
    #
    def toggle_debug
      @debug = @debug == false ? true : false
    end

    # Creates an instance to the Job class by passing a reference to self
    #
    def job
      JenkinsApi::Client::Job.new(self)
    end

    # Creates an instance to the System class by passing a reference to self
    #
    def system
      JenkinsApi::Client::System.new(self)
    end

    # Creates an instance to the Node class by passing a reference to self
    #
    def node
      JenkinsApi::Client::Node.new(self)
    end

    # Creates an instance to the View class by passing a reference to self
    #
    def view
      JenkinsApi::Client::View.new(self)
    end

    # Creates an instance to the BuildQueue by passing a reference to self
    #
    def queue
      JenkinsApi::Client::BuildQueue.new(self)
    end

    # Returns a string representing the class name
    #
    def to_s
      "#<JenkinsApi::Client>"
    end

    # Obtains the root of Jenkins server. This function is used to see if
    # Jenkins is running
    def get_root
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("/")
      request.basic_auth @username, @password
      http.request(request)
    end

    # Sends a GET request to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix
    #
    def api_get_request(url_prefix, tree = nil, url_suffix ="/api/json")
      url_prefix = "#{@jenkins_path}#{url_prefix}"
      http = Net::HTTP.start(@server_ip, @server_port)
      to_get = ""
      if tree
        to_get = "#{url_prefix}#{url_suffix}?#{tree}"
      else
        to_get = "#{url_prefix}#{url_suffix}"
      end
      to_get = URI.escape(to_get)
      request = Net::HTTP::Get.new(to_get)
      puts "[INFO] GET #{to_get}" if @debug
      request.basic_auth @username, @password
      response = http.request(request)
      msg = "HTTP Code: #{response.code}, Response Body: #{response.body}"
      case response.code.to_i
      when 200
        if url_suffix =~ /json/
          return JSON.parse(response.body)
        else
          return response
        end
      when 401
        raise Exceptions::UnautherizedException.new(msg)
      when 404
        raise Exceptions::NotFoundException.new(msg)
      when 500
        raise Exceptions::InternelServerErrorException.new(msg)
      else
        raise Exceptions::ApiException.new(msg)
      end
    end

    # Sends a POST message to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix
    # @param [Hash] form_data form data to send with POST request
    #
    def api_post_request(url_prefix, form_data = {})
      url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}")

      if @crumbs_enabled
        crumb_response = get_crumb
        form_data.merge!(
          {
            crumb_response["crumbRequestField"] => crumb_response["crumb"],
          }
        )
      end
      puts "[INFO] PUT #{url_prefix}" if @debug
      request.basic_auth @username, @password
      request.content_type = 'application/json'
      request.set_form_data(form_data) unless form_data.empty?
      response = http.request(request)
      handle_post_response(response)
    end

    # Obtains the configuration of a component from the Jenkins CI server
    #
    # @param [String] url_prefix
    #
    def get_config(url_prefix)
      url_prefix = URI.escape(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("#{url_prefix}/config.xml")
      puts "[INFO] GET #{url_prefix}/config.xml" if @debug
      request.basic_auth @username, @password
      response = http.request(request)
      response.body
    end

    # Posts the given xml configuration to the url given
    #
    # @param [String] url_prefix
    # @param [String] xml
    #
    def post_config(url_prefix, xml, form_data = {})
      url_prefix = URI.escape(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}")
      puts "[INFO] PUT #{url_prefix}" if @debug

      puts "POSTING: #{xml}"
      if @crumbs_enabled
        crumb_response = get_crumb
        form_data.merge!(
          {
            "mode" => "hudson.model.FreeStyleProject",
            #"mode" => "",
            crumb_response["crumbRequestField"] => crumb_response["crumb"],
          }
        )
      end
      request.basic_auth @username, @password
      request.body = xml
      request.content_type = 'application/xml'
      request.set_form_data(form_data) unless form_data.empty?
      puts "DEBUG: Crumb: #{form_data.inspect}"
      response = http.request(request)
      puts "DEBUG: response: #{response.inspect}"
      handle_post_response(response)
    end

    def use_crumbs?
      json = api_get_request("/")
      json["useCrumbs"]
    end

    def use_securit?
      json = api_get_request("/")
      json["useSecurity"]
    end

    # Obtains the jenkins version from the API
    #
    # @return Jenkins version
    #
    def get_jenkins_version
      response = get_root
      response["X-Jenkins"]
    end

    def get_hudson_version
      response = get_root
      response["X-Hudson"]
    end

    def get_server_date
      response = get_root
      response["Date"]
    end

    #private

    def get_crumb
      begin
        response = api_get_request("/crumbIssuer")
      rescue Exceptions::NotFoundException
        raise "You've asked to enable CSRF protection, but it looks like" +
          " your Jenkins server doesn't have this setting enabled. Please" +
          " change the Jenkins server setting or client configuration."
      end
    end

    def handle_post_response(response)
      msg = "HTTP Code: #{response.code}"
      msg << " Response Body: #{response.body}" if @debug
      case response.code.to_i
      when 200, 302
        return response.code
      when 404
        raise Exceptions::NotFoundException.new(msg)
      when 500
        raise Exceptions::InternelServerErrorException.new(msg)
      else
        raise Exceptions::ApiException.new(msg)
      end

    end

  end
end
