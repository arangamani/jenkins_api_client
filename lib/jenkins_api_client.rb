Dir[File.dirname(__FILE__) + '/jenkins_api_client/*.rb'].each do |file|
  require file
end
Dir[File.dirname(__FILE__) + '/jenkins_api_client/cli/*.rb'].each do |file|
  require file
end
