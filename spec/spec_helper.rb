require 'simplecov'
SimpleCov.start if ENV["COVERAGE"]
require File.expand_path('../../lib/jenkins_api_client', __FILE__)
require 'pp'
require 'yaml'

RSpec.configure do |config|
  config.mock_with :flexmock
end

module MockSpecHelper

end
