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
require 'net/https'
require 'nokogiri'
require 'base64'
require 'mixlib/shellout'
require 'uri'
require 'logger'
require 'socksify/http'
require 'open-uri'

# The main module that contains the Client class and all subclasses that
# communicate with the Jenkins's Remote Access API.
#
module JenkinsApi
  # This is the client class that acts as the bridge between the subclasses and
  # Jenkins. This class contains methods that performs GET and POST requests
  # for various operations.
  #
  class Client
    attr_accessor :timeout, :logger
    # Default port to be used to connect to Jenkins
    DEFAULT_SERVER_PORT = 8080
    # Default timeout in seconds to be used while performing operations
    DEFAULT_TIMEOUT = 120
    DEFAULT_HTTP_OPEN_TIMEOUT = 10
    DEFAULT_HTTP_READ_TIMEOUT = 120
    # Parameters that are permitted as options while initializing the client
    VALID_PARAMS = [
      "server_url",
      "server_ip",
      "server_port",
      "proxy_ip",
      "proxy_port",
      "proxy_protocol",
      "jenkins_path",
      "username",
      "password",
      "password_base64",
      "logger",
      "log_location",
      "log_level",
      "timeout",
      "http_open_timeout",
      "http_read_timeout",
      "ssl",
      "pkcs_file_path",
      "pass_phrase",
      "ca_file",
      "follow_redirects",
      "identity_file",
      "cookies"
    ].freeze

    # Initialize a Client object with Jenkins CI server credentials
    #
    # @param args [Hash] Arguments to connect to Jenkins server
    #
    # @option args [String] :server_ip the IP address of the Jenkins CI server
    # @option args [String] :server_port the port on which the Jenkins listens
    # @option args [String] :server_url the full URL address of the Jenkins CI server (http/https). This can include
    #   username/password. :username/:password options will override any user/pass value in the URL
    # @option args [String] :username the username used for connecting to the server (optional)
    # @option args [String] :password the password or API Key for connecting to the CI server (optional)
    # @option args [String] :password_base64 the password with base64 encoded format for connecting to the CI
    #   server (optional)
    # @option args [String] :identity_file the priviate key file for Jenkins CLI authentication,
    #   it is used only for executing CLI commands. Also remember to upload the public key to
    #   <Server IP>:<Server Port>/user/<Username>/configure
    # @option args [String] :proxy_ip the proxy IP address
    # @option args [String] :proxy_port the proxy port
    # @option args [String] :proxy_protocol the proxy protocol ('socks' or 'http' (defaults to HTTP)
    # @option args [String] :jenkins_path ("/") the optional context path for Jenkins
    # @option args [Boolean] :ssl (false) indicates if Jenkins is accessible over HTTPS
    # @option args [String] :pkcs_file_path ("/") the optional context path for pfx or p12 binary certificate file
    # @option args [String] :pass_phrase password for pkcs_file_path certificate file
    # @option args [String] :ca_file the path to a PEM encoded file containing trusted certificates used to verify peer certificate
    # @option args [Boolean] :follow_redirects this argument causes the client to follow a redirect (jenkins can
    #   return a 30x when starting a build)
    # @option args [Fixnum] :timeout (120) This argument sets the timeout for operations that take longer (in seconds)
    # @option args [Logger] :logger a Logger object, used to override the default logger (optional)
    # @option args [String] :log_location (STDOUT) the location for the log file
    # @option args [Fixnum] :log_level (Logger::INFO) The level for messages to be logged. Should be one of:
    #   Logger::DEBUG (0), Logger::INFO (1), Logger::WARN (2), Logger::ERROR (2), Logger::FATAL (3)
    # @option args [String] :cookies Cookies to be sent with all requests in the format: name=value; name2=value2
    #
    # @return [JenkinsApi::Client] a client object to Jenkins API
    #
    # @raise [ArgumentError] when required options are not provided.
    #
    def initialize(args)
      args = symbolize_keys(args)
      args.each do |key, value|
        if value && VALID_PARAMS.include?(key.to_s)
          instance_variable_set("@#{key}", value)
        end
      end if args.is_a? Hash

      # Server IP or Server URL must be specific
      unless @server_ip || @server_url
        raise ArgumentError, "Server IP or Server URL is required to connect" +
          " to Jenkins"
      end

      # Get info from the server_url, if we got one
      if @server_url
        server_uri = URI.parse(@server_url)
        @server_ip = server_uri.host
        @server_port = server_uri.port
        @ssl = server_uri.scheme == "https"
        @jenkins_path = server_uri.path

        # read username and password from the URL
        # only set if @username and @password are not already set via explicit options
        @username ||= server_uri.user
        @password ||= server_uri.password
      end

      # Username/password are optional as some jenkins servers do not require
      # authentication
      if @username && !(@password || @password_base64)
        raise ArgumentError, "If username is provided, password is required"
      end
      if @proxy_ip.nil? ^ @proxy_port.nil?
        raise ArgumentError, "Proxy IP and port must both be specified or" +
          " both left nil"
      end

      @jenkins_path ||= ""
      @jenkins_path.gsub!(/\/$/,"") # remove trailing slash if there is one
      @server_port = DEFAULT_SERVER_PORT unless @server_port
      @timeout = DEFAULT_TIMEOUT unless @timeout
      @http_open_timeout = DEFAULT_HTTP_OPEN_TIMEOUT unless @http_open_timeout
      @http_read_timeout = DEFAULT_HTTP_READ_TIMEOUT unless @http_read_timeout
      @ssl ||= false
      @proxy_protocol ||= 'http'

      # Setting log options
      if @logger
        raise ArgumentError, "logger parameter must be a Logger object" unless @logger.is_a?(Logger)
        raise ArgumentError, "log_level should not be set if using custom logger" if @log_level
        raise ArgumentError, "log_location should not be set if using custom logger" if @log_location
      else
        @log_location = STDOUT unless @log_location
        @log_level = Logger::INFO unless @log_level
        @logger = Logger.new(@log_location)
        @logger.level = @log_level
      end

      # Base64 decode inserts a newline character at the end. As a workaround
      # added chomp to remove newline characters. I hope nobody uses newline
      # characters at the end of their passwords :)
      @password = Base64.decode64(@password_base64).chomp if @password_base64

      # No connections are made to the Jenkins server during initialize to
      # allow the unit tests to behave normally as mocking is simpler this way.
      # If this variable is nil, the first POST request will query the API and
      # populate this variable.
      @crumbs_enabled = nil
      # The crumbs hash. Store it so that we don't have to obtain the crumb for
      # every POST request. It appears that the crumb doesn't change often.
      @crumb = {}
      # This is the number of times to refetch the crumb if it ever expires.
      @crumb_max_retries = 3
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

    # Creates an instance to the PluginManager by passing a reference to self
    #
    # @return [JenkinsApi::Client::PluginManager] an object to PluginManager
    #  subclass
    #
    def plugin
      JenkinsApi::Client::PluginManager.new(self)
    end

    # Creates an instance of the User class by passing a reference to self
    #
    # @return [JenkinsApi::Client::User] An object of User subclass
    #
    def user
      JenkinsApi::Client::User.new(self)
    end

    # Creates an instance of the Root class by passing a reference to self
    #
    # @return [JenkinsApi::Client::Root] An object of Root subclass
    #
    def root
      JenkinsApi::Client::Root.new(self)
    end

    # Returns a string representing the class name
    #
    # @return [String] string representation of class name
    #
    def to_s
      "#<JenkinsApi::Client>"
    end

    # Overrides the inspect method to get rid of the credentials being shown in
    # the in interactive IRB sessions and also when the `inspect` method is
    # called. Just print the important variables.
    #
    def inspect
      "#<JenkinsApi::Client:0x#{(self.__id__ * 2).to_s(16)}" +
        " @ssl=#{@ssl.inspect}," +
        " @ca_file=#{@ca_file.inspect}," +
        " @log_location=#{@log_location.inspect}," +
        " @log_level=#{@log_level.inspect}," +
        " @crumbs_enabled=#{@crumbs_enabled.inspect}," +
        " @follow_redirects=#{@follow_redirects.inspect}," +
        " @jenkins_path=#{@jenkins_path.inspect}," +
        " @timeout=#{@timeout.inspect}>," +
        " @http_open_timeout=#{@http_open_timeout.inspect}>," +
        " @http_read_timeout=#{@http_read_timeout.inspect}>"
    end

    # Connects to the server and downloads artifacts to a specified location
    #
    # @param [String] job_name
    # @param [String] filename location to save artifact
    #
    def get_artifact(job_name,filename)
      @artifact = job.find_artifact(job_name)
      response = make_http_request(Net::HTTP::Get.new(@artifact))
      if response.code == "200"
        File.write(File.expand_path(filename), response.body)
      else
        raise "Couldn't get the artifact"
      end
    end

    # Connects to the server and download all artifacts of a build to a specified location
    #
    # @param [String] job_name
    # @param [String] dldir location to save artifacts
    # @param [Integer] build_number optional, defaults to current build
    # @returns [String, Array] list of retrieved artifacts
    #
    def get_artifacts(job_name, dldir, build_number = nil)
      @artifacts = job.find_artifacts(job_name,build_number)
      results = []
      @artifacts.each do |artifact|
        uri = URI.parse(artifact)
        http = Net::HTTP.new(uri.host, uri.port)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.use_ssl = @ssl
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(@username, @password)
        response = http.request(request)
        # we want every thing after the last 'build' in the path to become the filename
        if artifact.include?('/build/')
          filename = artifact.split("/build/").last.gsub('/','-')
        else
          filename = File.basename(artifact)
        end
        filename = File.join(dldir, filename)
        results << filename
        if response.code == "200"
          File.write(File.expand_path(filename), response.body)
        else
          raise "Couldn't get the artifact #{artifact} for job #{job}"
        end
      end
      results
    end

    # Connects to the Jenkins server, sends the specified request and returns
    # the response.
    #
    # @param [Net::HTTPRequest] request The request object to send
    # @param [Boolean] follow_redirect whether to follow redirects or not
    #
    # @return [Net::HTTPResponse] Response from Jenkins
    #
    def make_http_request(request, follow_redirect = @follow_redirects)
      request.basic_auth @username, @password if @username
      request['Cookie'] = @cookies if @cookies

      if @proxy_ip
        case @proxy_protocol
        when 'http'
          http = Net::HTTP::Proxy(@proxy_ip, @proxy_port).new(@server_ip, @server_port)
        when 'socks'
          http = Net::HTTP::SOCKSProxy(@proxy_ip, @proxy_port).start(@server_ip, @server_port)
        else
          raise "unknown proxy protocol: '#{@proxy_protocol}'"
        end
      else
        http = Net::HTTP.new(@server_ip, @server_port)
      end

      if @ssl && @pkcs_file_path
        http.use_ssl = true
        pkcs12 =OpenSSL::PKCS12.new(File.binread(@pkcs_file_path), @pass_phrase!=nil ? @pass_phrase : "")
        http.cert = pkcs12.certificate
        http.key = pkcs12.key
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      elsif @ssl
        http.use_ssl = true

        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = @ca_file if @ca_file
      end
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout

      response = http.request(request)
      case response
        when Net::HTTPRedirection then
          # If we got a redirect request, follow it (if flag set), but don't
          # go any deeper (only one redirect supported - don't want to follow
          # our tail)
          if follow_redirect
            redir_uri = URI.parse(response['location'])
            response = make_http_request(
              Net::HTTP::Get.new(redir_uri.path, false)
            )
          end
      end

      # Pick out some useful header info before we return
      @jenkins_version = response['X-Jenkins']
      @hudson_version = response['X-Hudson']

      return response
    end
    protected :make_http_request

    # Obtains the root of Jenkins server. This function is used to see if
    # Jenkins is running
    #
    # @return [Net::HTTP::Response] Response from Jenkins for "/"
    #
    def get_root
      @logger.debug "GET #{@jenkins_path}/"
      request = Net::HTTP::Get.new("#{@jenkins_path}/")
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
    # @return [String, Hash] JSON response from Jenkins
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
      request = Net::HTTP::Get.new(to_get)
      @logger.debug "GET #{to_get}"
      response = make_http_request(request)
      if raw_response
        handle_exception(response, "raw")
      else
        handle_exception(response, "body", url_suffix =~ /json/)
      end
    end

    # Sends a POST message to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix The prefix to be used in the URL
    # @param [Hash] form_data Form data to send with POST request
    # @param [Boolean] raw_response Return complete Response object instead of
    #   JSON body of response
    #
    # @return [String] Response code form Jenkins Response
    #
    def api_post_request(url_prefix, form_data = {}, raw_response = false)
      retries = @crumb_max_retries
      begin
        refresh_crumbs

        # Added form_data default {} instead of nil to help with proxies
        # that barf with empty post
        request = Net::HTTP::Post.new("#{@jenkins_path}#{url_prefix}")
        @logger.debug "POST #{url_prefix}"
        if @crumbs_enabled
          request[@crumb["crumbRequestField"]] = @crumb["crumb"]
        end
        request.set_form_data(form_data)
        response = make_http_request(request)
        if raw_response
          handle_exception(response, "raw")
        else
          handle_exception(response)
        end
      rescue Exceptions::ForbiddenException => e
        refresh_crumbs(true)

        if @crumbs_enabled
          @logger.info "Retrying: #{@crumb_max_retries - retries + 1} out of" +
            " #{@crumb_max_retries} times..."
          retries -= 1

          if retries > 0
            retry
          else
            raise Exceptions::ForbiddenWithCrumb.new(@logger, e.message)
          end
        else
          raise
        end
      end
    end

    # Obtains the configuration of a component from the Jenkins CI server
    #
    # @param [String] url_prefix The prefix to be used in the URL
    #
    # @return [String] XML configuration obtained from Jenkins
    #
    def get_config(url_prefix)
      request = Net::HTTP::Get.new("#{@jenkins_path}#{url_prefix}/config.xml")
      @logger.debug "GET #{url_prefix}/config.xml"
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
      post_data(url_prefix, xml, 'application/xml;charset=UTF-8')
    end

    def post_json(url_prefix, json)
      post_data(url_prefix, json, 'application/json;charset=UTF-8')
    end

    def post_data(url_prefix, data, content_type)
      retries = @crumb_max_retries
      begin
        refresh_crumbs

        request = Net::HTTP::Post.new("#{@jenkins_path}#{url_prefix}")
        @logger.debug "POST #{url_prefix}"
        request.body = data
        request.content_type = content_type
        if @crumbs_enabled
          request[@crumb["crumbRequestField"]] = @crumb["crumb"]
        end
        response = make_http_request(request)
        handle_exception(response)
      rescue Exceptions::ForbiddenException => e
        refresh_crumbs(true)

        if @crumbs_enabled
          @logger.info "Retrying: #{@crumb_max_retries - retries + 1} out of" +
            " #{@crumb_max_retries} times..."
          retries -= 1

          if retries > 0
            retry
          else
            raise Exceptions::ForbiddenWithCrumb.new(@logger, e.message)
          end
        else
          raise
        end
      end
    end

    def init_update_center
      @logger.info "Initializing Jenkins Update Center..."
      @logger.debug "Obtaining the JSON data for Update Center..."
      # TODO: Clean me up
      update_center_data = open("https://updates.jenkins.io/current/update-center.json").read
      # The Jenkins mirror returns the data in the following format
      #   updateCenter.post(
      #     {.. JSON data...}
      #   );
      # which is used by the Javascript used by the Jenkins UI to send to Jenkins.
      #
      update_center_data.gsub!("updateCenter.post(\n", "")
      update_center_data.gsub!("\n);", "")

      @logger.debug "Posting the obtained JSON to Jenkins Update Center..."
      post_json("/updateCenter/byId/default/postBack", update_center_data)
    end

    # Checks if Jenkins uses crumbs (i.e) the XSS disable option is checked in
    # Jenkins' security settings
    #
    # @return [Boolean] whether Jenkins uses crumbs or not
    #
    def use_crumbs?
      response = api_get_request("", "tree=useCrumbs")
      response["useCrumbs"]
    end

    # Checks if Jenkins uses security
    #
    # @return [Boolean] whether Jenkins uses security or not
    #
    def use_security?
      response = api_get_request("", "tree=useSecurity")
      response["useSecurity"]
    end

    # Obtains the jenkins version from the API
    # Only queries Jenkins if the version is not already stored.
    # Note that the version is auto-updated after every request made to Jenkins
    # since it is returned as a header in every response
    #
    # @return [String] Jenkins version
    #
    def get_jenkins_version
      get_root if @jenkins_version.nil?
      @jenkins_version
    end

    # Obtain the Hudson version of the CI server
    # Only queries Hudson/Jenkins if the version is not already stored.
    # Note that the version is auto-updated after every request made to Jenkins
    # since it is returned as a header in every response
    #
    # @return [String] Version of Hudson on Jenkins server
    #
    def get_hudson_version
      get_root if @hudson_version.nil?
      @hudson_version
    end

    # Converts a version string to a list of integers
    # This makes it easier to compare versions since in 'version-speak',
    # v 1.2 is a lot older than v 1.102 - and simple < > on version
    # strings doesn't work so well
    def deconstruct_version_string(version)
      match = version.match(/^(\d+)\.(\d+)(?:\.(\d+))?$/)

      # Match should have 4 parts [0] = input string, [1] = major
      # [2] = minor, [3] = patch (possibly blank)
      if match && match.size == 4
        return [match[1].to_i, match[2].to_i, match[3].to_i || 0]
      else
        return nil
      end
    end

    # Compare two version strings (A and B)
    # if A == B, returns 0
    # if A > B, returns 1
    # if A < B, returns -1
    def compare_versions(version_a, version_b)
      if version_a == version_b
        return 0
      else
        version_a_d = deconstruct_version_string(version_a)
        version_b_d = deconstruct_version_string(version_b)

        if version_a_d[0] > version_b_d[0] ||
          (version_a_d[0] == version_b_d[0] && version_a_d[1] > version_b_d[1]) ||
          (version_a_d[0] == version_b_d[0] && version_a_d[1] == version_b_d[1] && version_a_d[2] > version_b_d[2])
          return 1
        else
          return -1
        end
      end
    end

    # Obtain the date of the Jenkins server
    #
    # @return [String] Server date
    #
    def get_server_date
      response = get_root
      response["Date"]
    end

    # Executes the provided groovy script on the Jenkins CI server
    #
    # @param [String] script_text The text of the groovy script to execute
    #
    # @return [String] The output of the executed groovy script
    #
    def exec_script(script_text)
      response = api_post_request('/scriptText', {'script' => script_text}, true)
      response.body
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
      cmd = "java -jar #{base_dir}/../../java_deps/jenkins-cli.jar -s #{server_url}"
      cmd << " -i #{@identity_file}" if @identity_file && !@identity_file.empty?
      cmd << " #{command}"
      cmd << " --username #{@username} --password #{@password}" if @identity_file.nil? || @identity_file.empty?
      cmd << ' '
      cmd << args.join(' ')
      java_cmd = Mixlib::ShellOut.new(cmd)

      # Run the command
      java_cmd.run_command
      if java_cmd.stderr.empty?
        java_cmd.stdout.chomp
      else
        # The stderr has a stack trace of the Java program. We'll already have
        # a stack trace for Ruby. So just display a descriptive message for the
        # error thrown by the CLI.
        raise Exceptions::CLIException.new(
          @logger,
          java_cmd.stderr.split("\n").first
        )
      end
    end

    private

    # Obtains the crumb from Jenkins' crumb issuer
    #
    # @return [Hash<String, String>] the crumb response from Jenkins' crumb
    #   issuer
    #
    # @raise Exceptions::CrumbNotFoundException if the crumb is not provided
    #   (i.e) XSS disable option is not checked in Jenkins' security setting
    #
    def get_crumb
      begin
        @logger.debug "Obtaining crumb from the jenkins server"
        api_get_request("/crumbIssuer")
      rescue Exceptions::NotFoundException
        raise Exceptions::CrumbNotFoundException.new(
          @logger,
          "CSRF protection is not enabled on the server at the moment." +
          " Perhaps the client was initialized when the CSRF setting was" +
          " enabled. Please re-initialize the client."
        )
      end
    end

    # Used to determine whether crumbs are enabled, and populate/clear our
    # local crumb accordingly.
    #
    # @param force_refresh [Boolean] determines whether the check is
    #   cursory or deeper.  The default is cursory - i.e. if crumbs
    #   enabled is 'nil' then figure out what to do, otherwise skip
    #   If 'true' the method will check to see if the crumbs require-
    #   ment has changed (by querying Jenkins), and updating crumb
    #   (refresh, delete, create) as appropriate.
    #
    def refresh_crumbs(force_refresh = false)
      # Quick check to see if someone has changed XSS settings and not
      # restarted us
      if force_refresh || @crumbs_enabled.nil?
        old_crumbs_setting = @crumbs_enabled
        new_crumbs_setting = use_crumbs?

        if old_crumbs_setting != new_crumbs_setting
          @crumbs_enabled = new_crumbs_setting
        end

        # Get or clear crumbs setting appropriately
        # Works as refresh if crumbs still enabled
        if @crumbs_enabled
          if old_crumbs_setting
            @logger.info "Crumb expired.  Refetching from the server."
          else
            @logger.info "Crumbs turned on.  Fetching from the server."
          end

          @crumb = get_crumb if force_refresh || !old_crumbs_setting
        else
          if old_crumbs_setting
            @logger.info "Crumbs turned off.  Clearing crumb."
            @crumb.clear
          end
        end
      end
    end

    # Private method.  Converts keys passed in as strings into symbols.
    #
    # @param hash [Hash] Hash containing arguments to login to jenkins.
    #
    def symbolize_keys(hash)
      hash.inject({}){|result, (key, value)|
        new_key = case key
          when String then key.to_sym
          else key
          end
        new_value = case value
          when Hash then symbolize_keys(value)
          else value
          end
        result[new_key] = new_value
        result
      }
    end

    # Private method that handles the exception and raises with proper error
    # message with the type of exception and returns the required values if no
    # exceptions are raised.
    #
    # @param [Net::HTTP::Response] response Response from Jenkins
    # @param [String] to_send What should be returned as a response. Allowed
    #   values: "code", "body", and "raw".
    # @param [Boolean] send_json Boolean value used to determine whether to
    #   load the JSON or send the response as is.
    #
    # @return [String, Hash] Response returned whether loaded JSON or raw
    #   string
    #
    # @raise [Exceptions::Unauthorized] When invalid credentials are
    #   provided to connect to Jenkins
    # @raise [Exceptions::NotFound] When the requested page on Jenkins is not
    #   found
    # @raise [Exceptions::InternalServerError] When Jenkins returns a 500
    #   Internal Server Error
    # @raise [Exceptions::ApiException] Any other exception returned from
    #   Jenkins that are not categorized in the API Client.
    #
    def handle_exception(response, to_send = "code", send_json = false)
      msg = "HTTP Code: #{response.code}, Response Body: #{response.body}"
      @logger.debug msg
      case response.code.to_i
      # As of Jenkins version 1.519, the job builds return a 201 status code
      # with a Location HTTP header with the pointing the URL of the item in
      # the queue.
      when 200, 201, 302
        if to_send == "body" && send_json
          return JSON.parse(response.body)
        elsif to_send == "body"
          return response.body
        elsif to_send == "code"
          return response.code
        elsif to_send == "raw"
          return response
        end
      when 400
        api_message = getApiMsgFromError404 response 
        @logger.debug "API message: #{api_message}"
        case api_message
        when /A job already exists with the name/
          raise Exceptions::JobAlreadyExists.new(@logger, api_message)
        when /A view already exists with the name/
          raise Exceptions::ViewAlreadyExists.new(@logger, api_message)
        when /Slave called .* already exists/
          raise Exceptions::NodeAlreadyExists.new(@logger, api_message)
        when /Nothing is submitted/
          raise Exceptions::NothingSubmitted.new(@logger, api_message)
        else
          raise Exceptions::ApiException.new(@logger, api_message)
        end
      when 401
        raise Exceptions::Unauthorized.new @logger
      when 403
        raise Exceptions::Forbidden.new @logger
      when 404
        raise Exceptions::NotFound.new @logger
      when 500
        matched = response.body.match(/Exception: (.*)<br>/)
        api_message = matched[1] unless matched.nil?
        @logger.debug "API message: #{api_message}"
        raise Exceptions::InternalServerError.new(@logger, api_message)
      when 503
        raise Exceptions::ServiceUnavailable.new @logger
      else
        raise Exceptions::ApiException.new(
          @logger,
          "Error code #{response.code}"
        )
      end
    end

    def getApiMsgFromError404(response)

      matched = response.body.match(/<p>(.*)<\/p>/)
      # unless matched.nil?
      if (matched != nil)
        result = matched[1]
      else
        
        matched = response.body.match(/<h2>(.*)<\/h2>/)
        if (matched != nil)
          result = matched[1]
        else
          result = nil
        end
      end

      return result
    end

  end
end
