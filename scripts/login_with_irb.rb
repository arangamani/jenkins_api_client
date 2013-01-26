# This script provides an easier way to login to Jenkins server API.
# It logs you in with the credentials and server details you proided and then
# starts an IRB session so you can interactively play with the API.

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
require 'jenkins_api_client'
require 'yaml'
require 'irb'

begin
  @client = JenkinsApi::Client.new(YAML.load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))
  puts "logged-in to the Jenkins API, use the '@client' variable to use the client"
end

IRB.start
