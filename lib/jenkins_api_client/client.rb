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
require File.expand_path('../system', __FILE__)
require File.expand_path('../node', __FILE__)

module JenkinsApi
  class Client
    attr_accessor :debug
    DEFAULT_SERVER_PORT = 8080
    VALID_PARAMS = %w(server_ip server_port username password debug)

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
     @debug = false unless @debug

     # Base64 decode inserts a newline character at the end. As a workaround added chomp
     # to remove newline characters. I hope nobody uses newline characters at the end of
     # their passwords :)
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
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("#{url_prefix}#{url_suffix}")
      puts "[INFO] GET #{url_prefix}#{url_suffix}" if @debug
      request = Net::HTTP::Get.new("#{url_prefix}#{url_suffix}?#{tree}") if tree
      request.basic_auth @username, @password
      response = http.request(request)
      case response.code.to_i
      when 200
        if url_suffix =~ /json/
          return JSON.parse(response.body)
        else
          return response
        end
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
      puts "[INFO] PUT #{url_prefix}" if @debug
      request.basic_auth @username, @password
      request.content_type = 'application/json'
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
    def post_config(url_prefix, xml)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}")
      puts "[INFO] PUT #{url_prefix}" if @debug
      request.basic_auth @username, @password
      request.body = xml
      request.content_type = 'application/xml'
      response = http.request(request)
      response.code
    end

  end
end
