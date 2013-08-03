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

# The main module that contains the Client class and all subclasses that
# communicate with the Jenkins's Remote Access API.
#
module JenkinsApi
  # This is the client class that acts as the bridge between the subclasses and
  # Jnekins. This class contains methods that performs GET and POST requests
  # for various operations.
  #
  class Client
    attr_accessor :timeout, :logger
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
      "log_location",
      "log_level",
      "timeout",
      "ssl",
      "follow_redirects",
      "identity_file"
    ].freeze

    # Initialize a Client object with Jenkins CI server credentials
    #
    # @param args [Hash] Arguments to connect to Jenkins server
    #
    # @option args [String] :server_ip
    #   the IP address of the Jenkins CI server
    # @option args [String] :server_port
    #   the port on which the Jenkins listens
    # @option args [String] :server_url
    #   the full URL address of the Jenkins CI server (http/https)
    # @option args [String] :username
    #   the username used for connecting to the server (optional)
    # @option args [String] :password
    #   the password for connecting to the CI server (optional)
    # @option args [String] :password_base64
    #   the password with base64 encoded format for connecting to the CI
    #   server (optional)
    # @option args [String] :identity_file
    #   the priviate key file for Jenkins CLI authentication,
    #   it is used only for executing CLI commands.
    #   also remember to upload the public key to http://#{server_ip}:#{server_port}/user/#{my_username}/configure
    # @option args [String] :proxy_ip
    #   the proxy IP address
    # @option args [String] :proxy_port
    #   the proxy port
    # @option args [String] :jenkins_path
    #   the optional context path for Jenkins
    # @option args [Boolean] :ssl
    #   indicates if Jenkins is accessible over HTTPS (defaults to false)
    # @option args [Boolean] :follow_redirects
    #   This argument causes the client to follow a redirect (jenkins can
    #   return a 30x when starting a build)
    # @option args [Fixnum] :timeout
    #   This argument sets the timeout for the jenkins system to become ready
    # @option args [String] :log_location
    #   The location for the log file (Defaults to STDOUT)
    # @option args [Fixnum] :log_level
    #   The level for messages to be logged. Should be one of:
    #   Logger::DEBUG (0), Logger::INFO (1), Logger::WARN (2), Logger::ERROR
    #   (2), Logger::FATAL (3) (Defaults to Logger::INFO)
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

      # Server IP or Server URL must be specifiec
      unless @server_ip || @server_url
        raise ArgumentError, "Server IP or Server URL is required to connect" +
          " to Jenkins"
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

      # Get info from the server_url, if we got one
      if @server_url
        server_uri = URI.parse(@server_url)
        @server_ip = server_uri.host
        @server_port = server_uri.port
        @ssl = server_uri.scheme == "https"
        @jenkins_path = server_uri.path
      end

      @jenkins_path ||= ""
      @jenkins_path.gsub!(/\/$/,"") # remove trailing slash if there is one
      @server_port = DEFAULT_SERVER_PORT unless @server_port
      @timeout = DEFAULT_TIMEOUT unless @timeout
      @ssl ||= false

      # Setting log options
      @log_location = STDOUT unless @log_location
      @log_level = Logger::INFO unless @log_level
      @logger = Logger.new(@log_location)
      @logger.level = @log_level


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

    # Creates an instance of the User class by passing a reference to self
    #
    # @return [JenkinsApi::Client::User] An object of User subclass
    #
    def user
      JenkinsApi::Client::User.new(self)
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
        " @log_location=#{@log_location.inspect}," +
        " @log_level=#{@log_level.inspect}," +
        " @crumbs_enabled=#{@crumbs_enabled.inspect}," +
        " @follow_redirects=#{@follow_redirects.inspect}," +
        " @jenkins_path=#{@jenkins_path.inspect}," +
        " @timeout=#{@timeout.inspect}>"
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

      if @proxy_ip
        http = Net::HTTP::Proxy(@proxy_ip, @proxy_port).new(@server_ip, @server_port)
      else
        http = Net::HTTP.new(@server_ip, @server_port)
      end

      if @ssl
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

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
      return response
    end
    protected :make_http_request

    # Obtains the root of Jenkins server. This function is used to see if
    # Jenkins is running
    #
    # @return [Net::HTTP::Response] Response from Jenkins for "/"
    #
    def get_root
      @logger.info "GET /"
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
      @logger.info "GET #{to_get}"
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
    #
    # @return [String] Response code form Jenkins Response
    #
    def api_post_request(url_prefix, form_data = {}, raw_response = false)
      retries = @crumb_max_retries
      begin
        refresh_crumbs

        # Added form_data default {} instead of nil to help with proxies
        # that barf with empty post
        url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
        request = Net::HTTP::Post.new("#{url_prefix}")
        @logger.info "POST #{url_prefix}"
        request.content_type = 'application/json'
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
      url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
      request = Net::HTTP::Get.new("#{url_prefix}/config.xml")
      @logger.info "GET #{url_prefix}/config.xml"
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
      retries = @crumb_max_retries
      begin
        refresh_crumbs

        url_prefix = URI.escape("#{@jenkins_path}#{url_prefix}")
        request = Net::HTTP::Post.new("#{url_prefix}")
        @logger.info "POST #{url_prefix}"
        request.body = xml
        request.content_type = 'application/xml'
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

    # Checks if Jenkins uses crumbs (i.e) the XSS disable option is checked in
    # Jenkins' security settings
    #
    # @return [Boolean] whether Jenkins uses crumbs or not
    #
    def use_crumbs?
      response = api_get_request("")
      response["useCrumbs"]
    end

    # Checks if Jenkins uses security
    #
    # @return [Boolean] whether Jenkins uses security or not
    #
    def use_security?
      response = api_get_request("")
      response["useSecurity"]
    end

    # Obtains the jenkins version from the API
    #
    # @return Jenkins version
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
    # @param +force_refresh+ [Boolean] Determines whether the check is
    #        cursory or deeper.  The default is cursory - i.e. if crumbs
    #        enabled is 'nil' then figure out what to do, otherwise skip
    #        If 'true' the method will check to see if the crumbs require-
    #        ment has changed (by querying Jenkins), and updating crumb
    #        (refresh, delete, create) as appropriate.
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
    # @return [String, JSON] Response returned whether loaded JSON or raw
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
        matched = response.body.match(/<p>(.*)<\/p>/)
        api_message = matched[1] unless matched.nil?
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
        raise Exceptions::InternalServerError.new @logger
      when 503
        raise Exceptions::ServiceUnavailable.new @logger
      else
        raise Exceptions::ApiException.new(
          @logger,
          "Error code #{response.code}"
        )
      end
    end

  end
end
