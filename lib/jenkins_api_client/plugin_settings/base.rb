module JenkinsApi
  class Client
    module PluginSettings
      class InvalidType < Exception; end

      class Base 
        def configure
          raise InvalidType, 'Object must inherit from JenkinsApi::Client::PluginSettings::Base and override configure method'
        end
      end
    end
  end
end
