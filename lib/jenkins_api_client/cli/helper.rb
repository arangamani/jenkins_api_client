
module JenkinsApi
  module CLI
    class Helper

      def self.setup(options)
        if options[:username] && options[:server_ip] && (options[:password] || options[:password_base64])
          creds = options
        elsif options[:creds_file]
          creds = YAML.load_file(File.expand_path(options[:creds_file], __FILE__))
        elsif File.exist?("#{ENV['HOME']}/.jenkins_api_client/login.yml")
          creds = YAML.load_file(File.expand_path("#{ENV['HOME']}/.jenkins_api_client/login.yml", __FILE__))
        else
          say "Credentials are not set. Please pass them as parameters or set them in the default credentials file", :red
        end
          JenkinsApi::Client.new(creds)
      end
    end
  end
end
