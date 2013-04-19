# This script provides an easier way to login to Jenkins server API.
# It logs you in with the credentials and server details you proided and then
# starts an IRB session so you can interactively play with the API.

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
require 'jenkins_api_client'
require 'yaml'
require 'irb'

def prompt_for_username
  get_from_stdin("Username: ", false)
end

def prompt_for_password
  get_from_stdin("Password: ", true)
end

def get_from_stdin(prompt, mask = false)
  $stdout.write(prompt)
  
  begin
    Kernel::system "stty -echo" if mask == true
    ret = gets.chomp!
  ensure
    if mask == true
      Kernel::system "stty echo"
      puts ""
    end
  end

  ret
end

if ARGV.empty?
  config_file = '~/.jenkins_api_client/login.yml'
else
  config_file = ARGV.shift
end

begin
  client_opts = YAML.load_file(File.expand_path(config_file))
  unless client_opts.has_key?(:username)
    client_opts[:username] = prompt_for_username()
  end
  unless client_opts.has_key?(:password) or client_opts.has_key?(:password_base64)
    client_opts[:password] = prompt_for_password()
  end
  
  @client = JenkinsApi::Client.new(client_opts)
  puts "logged-in to the Jenkins API, use the '@client' variable to use the client"
end

IRB.start
