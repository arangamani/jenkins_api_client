require 'thor'
require 'thor/group'

module JenkinsApi
  module CLI
    # This class provides various command line operations related to the credentials configuration.
    class Config < Thor
      include Thor::Actions

      desc "list", "List credentials"
      # CLI command to list the current login.yml credentials
      def list
        if File.exist?("#{ENV['HOME']}/.jenkins_api_client/login.yml")
          creds = YAML.load_file(
            File.expand_path(
              "#{ENV['HOME']}/.jenkins_api_client/login.yml", __FILE__
            )
          )
          creds.each { |key, value| puts "#{key}: #{value}" }
        else
          puts "login.yml file does not exist"
          exit 1
        end
      end

      desc "add", "Add new credentials to the login.yml file"
      # CLI command that creates and adds the creds to the login.yml file
      def add
        if parent_options[:username] && parent_options[:server_ip] && \
          (parent_options[:password] || parent_options[:password_base64])
          creds = parent_options
        elsif parent_options[:creds_file]
          creds = YAML.load_file(
            File.expand_path(parent_options[:creds_file], __FILE__)
          )
        else
          msg = "Credentials are not set. Please pass them as parameters or"
          msg << " set them in a credentials file"
          puts msg
          exit 1
        end

        FileUtils.mkdir_p("#{ENV['HOME']}/.jenkins_api_client")
        File.open("#{ENV['HOME']}/.jenkins_api_client/login.yml", 'w') { |f| YAML.dump(creds, f) }
      end
    end
  end
end
