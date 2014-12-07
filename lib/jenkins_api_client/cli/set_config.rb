#!/usr/software/bin/ruby-2.0.0

# This script sets the yaml file automatically after recording user input

require 'thor'
require 'thor/group'


class Setconfig < Thor
      
      desc "setup", "set up your config file once for all"
                  # CLI command that sets up login config
                  
                  option :username
                  option :password
                  option :server_ip
                  option :server_port
                  option :jenkins_api_token

                  def setup
                  yml_file_name = File.expand_path('~/.jenkins_api_client/login.yml')
                  user_yml_file_path = File.expand_path('~/.jenkins_api_client/')
                        Dir.mkdir(user_yml_file_path) unless File.directory?(user_yml_file_path)
                        
                        doc = <<FILE
:server_ip: #{options[:server_ip]}
:server_port: #{options[:server_port]}
:username: #{options[:username]}
:password: #{options[:password]}
:jenkins_api_token: #{options[:jenkins_api_token]}
FILE

                        File.new(yml_file_name, 'w')
                        File.open(yml_file_name, 'w') {|f| f.write(doc) }
                        
                        if [File.file?(yml_file_name)]
                              puts "succesfully wrote yml config file : "+ yml_file_name+"\n"
                        else
                              puts "failed to write yml config file\n"
                        end
                  end
            end