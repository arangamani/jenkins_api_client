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
require 'base64'
require "mixlib/shellout"

# The main module that contains the Client class and all subclasses that
# communicate with the Jenkins's Remote Access API.
#
module JenkinsApi
  # This is the client class that acts as the bridge between the subclasses and
  # Jnekins. This class contains methods that performs GET and POST requests
  # for various operations.
  #
  class Client
    attr_accessor :debug, :timeout
    # Default port to be used to connect to Jenkins
    DEFAULT_SERVER_PORT = 8080
    # Default timeout in seconds to be used while performing operations
    DEFAULT_TIMEOUT = 120
    # Parameters that are permitted as options while initializing the client
    VALID_PARAMS = [
      "server_url",
      "server_ip",
      "server_port",
      "proxy_ip",
      "proxy_port",
      "jenkins_path",
      "username",
      "password",
      "password_base64",
      "debug",
      "timeout",
      "ssl",
      "follow_redirects"
    ].freeze

    # Initialize a Client object with Jenkins CI server credentials
    #
    # @param [Hash] args
    #  * the +:server_ip+ param is the IP address of the Jenkins CI server
    #  * the +:server_port+ param is the port on which the Jenkins listens
    #  * the +:server_url+ param is the full URL address of the Jenkins CI server (http/https)
    #  * the +:username+ param is the username used for connecting to the server (optional)
    #  * the +:password+ param is the password for connecting to the CI server (optional)
    #  * the +:proxy_ip+ param is the proxy IP address
    #  * the +:proxy_port+ param is the proxy port
    #  * the +:jenkins_path+ param is the optional context path for Jenkins
    #  * the +:ssl+ param indicates if Jenkins is accessible over HTTPS
    #    (defaults to false)
    #  * the +:follow_redirects+ param will cause the client to follow a redirect
    #    (jenkins can return a 30x when starting a build)
    #
    # @return [JenkinsApi::Client] a client object to Jenkins API
    #
    # @raise [ArgumentError] when required options are not provided.
    #
    def initialize(args)
      args.each do |key, value|
        if value && VALID_PARAMS.include?(key.to_s)
          instance_variable_set("@#{key}", value)
        end
      end if args.is_a? Hash
      unless @server_ip || @server_url
        raise ArgumentError, "Server IP or Server URL is required to connect to Jenkins"
      end
      # Username/password are optional as some jenkins servers do not require auth
      if @username && !(@password || @password_base64)
        raise ArgumentError, "If username is provided, password is required"
      end
      if @proxy_ip.nil? ^ @proxy_port.nil?
        raise ArgumentError, "Proxy IP and port must both be specified or" +
          " both left nil"
      end
      @server_uri = URI.parse(@server_url) if @server_url
      @server_port = DEFAULT_SERVER_PORT unless @server_port
      @timeout = DEFAULT_TIMEOUT unless @timeout
      @ssl ||= false
      @ssl = @server_uri.scheme == "https" if @server_uri
      @debug = false unless @debug

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
    # @return [JenkinsApi::Client::Job] An object to Job subclass
    #
    def job
      JenkinsApi::Client::Job.new(self)
    end

    # Creates an instance to the System class by passing a reference to self
    #
    # @return [JenkinsApi::Client::System] An object to System subclass
    #
    def system
      JenkinsApi::Client::System.new(self)
    end

    # Creates an instance to the Node class by passing a reference to self
    #
    # @return [JenkinsApi::Client::Node] An object to Node subclass
    #
    def node
      JenkinsApi::Client::Node.new(self)
    end

    # Creates an instance to the View class by passing a reference to self
    #
    # @return [JenkinsApi::Client::View] An object to View subclass
    #
    def view
      JenkinsApi::Client::View.new(self)
    end

    # Creates an instance to the BuildQueue by passing a reference to self
    #
    # @return [JenkinsApi::Client::BuildQueue] An object to BuildQueue subclass
    #
    def queue
      JenkinsApi::Client::BuildQueue.new(self)
    end

    # Returns a string representing the class name
    #
    # @return [String] string representation of class name
    #
    def to_s
      "#<JenkinsApi::Client>"
    end

    # Connects to the Jenkins server, sends the specified request and returns
    # the response.
    #
    # @param [Net::HTTPRequest] request The request object to send
    #
    # @return [Net::HTTPResponse] Response from Jenkins
    #
    def make_http_request( request, follow_redirect = @follow_redirects )
      request.basic_auth @username, @password if @username

      if @server_url
        http = Net::HTTP.new(@server_uri.host, @server_uri.port)
        http.use_ssl = true if @ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @ssl
        response = http.request(request)
      else
        Net::HTTP.start(
          @server_ip, @server_port, @proxy_ip, @proxy_port, :use_ssl => @ssl
        ) do |http|
          response = http.request(request)
        end
      end
      case response
        when Net::HTTPRedirection then
          # If we got a redirect request, follow it (if flag set), but don't go any deeper
          # (only one redirect supported - don't want to follow our tail)
          redir_uri = URI.parse(response['location'])
          response = make_http_request(Net::HTTP::Get.new(redir_uri.path), false) if follow_redirect
      end
      return response
    end
    protected :make_http_request

    # Obtains the root of Jenkins server. This function is used to see if
    # Jenkins is running
    #
    # @return [Net::HTTP::Response] Response from Jenkins for "/"
    #
    def get_root
      request = Net::HTTP::Get.new("/")
      make_http_request(request)
    end

    # Sends a GET request to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix The prefix to use in the URL
    # @param [String] tree A specific JSON tree to optimize the API call
    # @param [String] url_suffix The suffix to be used in the URL
    # @param [Boolean] raw_response Return complete Response object instead of
    #   JSON body of response
    #
    # @return [String, JSON] JSON response from Jenkins
    #
    def api_get_request(url_prefix, tree = nil, url_suffix ="/api/json",
                        raw_response = false)
      url_prefix = "#{@jenkins_path}#{url_prefix}"
      to_get = ""
      if tree
        to_get = "#{url_prefix}#{url_suffix}?#{tree}"
      else
        to_get = "#{url_prefix}#{url_suffix}"
      end
      to_get = URI.escape(to_get)
      request = Net::HTTP::Get.new(to_get)
      puts "[INFO] GET #{to_get}" if @debug
      response = make_http_request(request)
      if raw_response
        response
      else
        handle_exception(response, "body", url_suffix =~ /json/)
      end
    end

    # Sends a POST message to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix The prefix to be used in the URL
    # @param [Hash] form_data Form data to send with POST request
    #
    # @return [String] Response code form Jenkins Response
    #
    def api_post_request(url_prefix, form_data = {})
      # Added form_data default {} instead of nil to help with proxies that
      # barf with empty post
      url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
      request = Net::HTTP::Post.new("#{url_prefix}")
      puts "[INFO] POST #{url_prefix}" if @debug
      request.content_type = 'application/json'
      request.set_form_data(form_data)
      response = make_http_request(request)
      handle_exception(response)
    end

    # Obtains the configuration of a component from the Jenkins CI server
    #
    # @param [String] url_prefix The prefix to be used in the URL
    #
    # @return [String] XML configuration obtained from Jenkins
    #
    def get_config(url_prefix)
      url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
      request = Net::HTTP::Get.new("#{url_prefix}/config.xml")
      puts "[INFO] GET #{url_prefix}/config.xml" if @debug
      response = make_http_request(request)
      handle_exception(response, "body")
    end

    # Posts the given xml configuration to the url given
    #
    # @param [String] url_prefix The prefix to be used in the URL
    # @param [String] xml The XML configuration to be sent to Jenkins
    #
    # @return [String] Response code returned from Jenkins
    #
    def post_config(url_prefix, xml)
      url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
      request = Net::HTTP::Post.new("#{url_prefix}")
      puts "[INFO] PUT #{url_prefix}" if @debug
      request.body = xml
      request.content_type = 'application/xml'
      response = make_http_request(request)
      handle_exception(response)
    end

    # Obtain the version of Jenkins CI server
    #
    # @return [String] Version of Jenkins
    #
    def get_jenkins_version
      response = get_root
      response["X-Jenkins"]
    end

    # Obtain the Hudson version of the CI server
    #
    # @return [String] Version of Hudson on Jenkins server
    #
    def get_hudson_version
      response = get_root
      response["X-Hudson"]
    end

    # Obtain the date of the Jenkins server
    #
    # @return [String] Server date
    #
    def get_server_date
      response = get_root
      response["Date"]
    end

    # Execute the Jenkins CLI
    #
    # @param command [String] command name
    # @param args [Array] the arguments for the command
    #
    # @return [String] command output from the CLI
    #
    # @raise [Exceptions::CLIException] if there are issues in running the
    #   commands using CLI
    #
    def exec_cli(command, args = [])
      base_dir = File.dirname(__FILE__)
      server_url = "http://#{@server_ip}:#{@server_port}/#{@jenkins_path}"
      cmd = "java -jar #{base_dir}/../../java_deps/jenkins-cli.jar" +
        " -s #{server_url} #{command}" +
        " --username #{@username} --password #{@password} " +
        args.join(' ')
      java_cmd = Mixlib::ShellOut.new(cmd)

      # Run the command
      java_cmd.run_command
      if java_cmd.stderr.empty?
        java_cmd.stdout.chomp
      else
        # The stderr has a stack trace of the Java program. We'll already have
        # a stack trace for Ruby. So just display a descriptive message for the
        # error thrown by the CLI.
        raise Exceptions::CLIException.new(java_cmd.stderr.split("\n").first)
      end
    end

    private

    # Private method that handles the exception and raises with proper error
    # message with the type of exception and returns the required values if no
    # exceptions are raised.
    #
    # @param [Net::HTTP::Response] response Response from Jenkins
    # @param [String] to_send What should be returned as a response. Allowed
    #   values: "code" and "body".
    # @param [Boolean] send_json Boolean value used to determine whether to
    #   load the JSON or send the response as is.
    #
    # @return [String, JSON] Response returned whether loaded JSON or raw
    #   string
    #
    # @raise [Exceptions::UnauthorizedException] When invalid credentials are
    #   provided to connect to Jenkins
    # @raise [Exceptions::NotFoundException] When the requested page on Jenkins
    #   is found
    # @raise [Exceptions::InternelServerErrorException] When Jenkins returns a
    #   500 Internel Server Error
    # @raise [Exceptions::ApiException] Any other exception returned from
    #   Jenkins that are not categorized in the API Client.
    #
    def handle_exception(response, to_send = "code", send_json = false)
      msg = "HTTP Code: #{response.code}, Response Body: #{response.body}"
      puts msg if @debug
      case response.code.to_i
      when 200, 302
        if to_send == "body" && send_json
          return JSON.parse(response.body)
        elsif to_send == "body"
          return response.body
        elsif to_send == "code"
          return response.code
        end
      when 400
        case response.body
        when /A job already exists with the name/
          raise Exceptions::JobAlreadyExistsWithName.new
        when /Nothing is submitted/
          raise Exceptions::NothingSubmitted.new
        else
          raise Exceptions::ApiException.new("Error code 400")
        end
      when 401
        raise Exceptions::UnautherizedException.new
      when 404
        raise Exceptions::NotFoundException.new
      when 500
        raise Exceptions::InternelServerErrorException.new
      else
        raise Exceptions::ApiException.new("Error code #{response.code}")
      end
    end

  end
end
