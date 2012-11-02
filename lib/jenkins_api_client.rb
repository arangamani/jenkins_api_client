Dir[File.dirname(__FILE__) + '/jenkins_api_client/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/jenkins_api_client/cli/*.rb'].each {|file| require file }
