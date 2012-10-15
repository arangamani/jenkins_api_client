require 'rubygems'
require 'json'
require 'net/http'
require 'nokogiri'
require 'active_support/core_ext'
require 'active_support/builder'

require File.expand_path('../version', __FILE__)
require File.expand_path('../exceptions', __FILE__)
require File.expand_path('../job', __FILE__)

module JenkinsApi
  class Client

    attr_accessor :server_ip, :server_port, :username, :password
    DEFAULT_SERVER_PORT = 8080
    VALID_PARAMS = %w(server_ip server_port username password)

    # @param [Hash] args
    def initialize(args)
      args.each { |key, value|
        instance_variable_set("@#{key}", value) if value
      } if args.is_a? Hash
     raise "Server IP is required to connect to Jenkins Server" unless @server_ip
     raise "Credentials are required to connect to te Jenkins Server" unless @username && @password
     @server_port = DEFAULT_SERVER_PORT unless @server_port
    end

    def job
      JenkinsApi::Client::Job.new(self)
    end

    def to_s
      "#<JenkinsApi::Client>"
    end

    def api_get_request(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("#{url_prefix}/api/json")
      request.basic_auth @username, @password
      response = http.request(request)
      JSON.parse(response.body)
    end

    def api_post_request(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}")
      request.basic_auth @username, @password
      response = http.request(request)
    end


    def get_config(url_prefix)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Get.new("#{url_prefix}/config.xml")
      request.basic_auth @username, @password
      response = http.request(request)
      response.body
    end

    def post_config(url_prefix, xml)
      http = Net::HTTP.start(@server_ip, @server_port)
      request = Net::HTTP::Post.new("#{url_prefix}/config.xml")
      request.basic_auth @username, @password
      request.body = xml
      response = http.request(request)
      response.code
    end

  end
end
