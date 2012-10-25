require 'rubygems'
require 'json'
require 'net/http'
require 'nokogiri'
require 'active_support/core_ext'
require 'active_support/builder'
require 'base64'

require File.expand_path('../version', __FILE__)
require File.expand_path('../exceptions', __FILE__)
require File.expand_path('../job', __FILE__)

module JenkinsApi
  class Client

    DEFAULT_SERVER_PORT = 8080
    VALID_PARAMS = %w(server_ip server_port username password)

    # Initialize a Client object with Jenkins CI server information and credentials
    #
    # @param [Hash] args
    #  * the +:server_ip+ param is the IP address of the Jenkins CI server
    #  * the +:server_port+ param is the port on which the Jenkins server listens
    #  * the +:username+ param is the username used for connecting to the CI server
    #  * the +:password+ param is the password for connecting to the CI server
    #
    def initialize(args)
      args.each { |key, value|
        instance_variable_set("@#{key}", value) if value
      } if args.is_a? Hash
     raise "Server IP is required to connect to Jenkins Server" unless @server_ip
     raise "Credentials are required to connect to te Jenkins Server" unless @username && (@password || @password_base64)
     @server_port = DEFAULT_SERVER_PORT unless @server_port

     # Base64 decode inserts a newline character at the end. As a workaround added chomp
     # to remove newline characters. I hope nobody uses newline characters at the end of
     # their passwords :)
     @password = Base64.decode64(@password_base64).chomp if @password_base64
    end

    # Creates an instance to the Job object by passing a reference to self
    #
    def job
      JenkinsApi::Client::Job.new(self)
    end

    # Returns a string representing the class name
    #
    def to_s
      "#<JenkinsApi::Client>"
    end

    # Sends a GET request to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix
    #
    def api_get_request(url_prefix, tree = nil)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("#{url_prefix}/api/json")
      request = Net::HTTP::Get.new("#{url_prefix}/api/json?#{tree}") if tree
      request.basic_auth @username, @password
      response = http.request(request)
      case response.code.to_i
      when 200
        return JSON.parse(response.body)
      when 401
        raise Exceptions::UnautherizedException.new("HTTP Code: #{response.code.to_s}, Response Body: #{response.body}")
      when 404
        raise Exceptions::NotFoundException.new("HTTP Code: #{response.code.to_s}, Response Body: #{response.body}")
      when 500
        raise Exceptions::InternelServerErrorException.new("HTTP Code: #{response.code.to_s}, Response Body: #{response.body}")
      else
        raise Exceptions::ApiException.new("HTTP Code: #{response.code.to_s}, Response body: #{response.body}")
      end
    end

    # Sends a POST message to the Jenkins CI server with the specified URL
    #
    # @param [String] url_prefix
    #
    def api_post_request(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}")
      request.basic_auth @username, @password
      response = http.request(request)
      case response.code.to_i
      when 200, 302
        return response.code
      when 404
        raise Exceptions::NotFoundException.new("HTTP Code: #{response.code.to_s}, Response Body: #{response.body}")
      when 500
        raise Exceptions::InternelServerErrorException.new("HTTP Code: #{response.code.to_s}, Response Body: #{response.body}")
      else
        raise Exceptions::ApiException.new("HTTP Code: #{response.code.to_s}, Response body: #{response.body}")
      end
    end

    # Obtains the configuration of a component from the Jenkins CI server
    #
    # @param [String] url_prefix
    #
    def get_config(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("#{url_prefix}/config.xml")
      request.basic_auth @username, @password
      response = http.request(request)
      response.body
    end

    # Posts the given xml configuration to the url given
    #
    # @param [String] url_prefix
    # @param [String] xml
    #
    def post_config(url_prefix, xml)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}")
      request.basic_auth @username, @password
      request.body = xml
      request.content_type = 'application/xml'
      response = http.request(request)
      response.code
    end

  end
end
