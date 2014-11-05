require 'forwardable'

module JenkinsApi
  class Client
    module PluginSettings
      class Collection 
        extend Forwardable

        def_delegator :@plugin_settings, :size

        def initialize(*plugin_settings)
          raise JenkinsApi::Client::PluginSettings::InvalidType unless plugin_settings.all? { |p| p.is_a?(JenkinsApi::Client::PluginSettings::Base) }
          @plugin_settings = plugin_settings
        end

        def add(plugin)
          raise JenkinsApi::Client::PluginSettings::InvalidType unless plugin.is_a?(JenkinsApi::Client::PluginSettings::Base)
          tap do |x|
            if @plugin_settings.none? { |p| p.class == plugin.class }
              @plugin_settings << plugin
            end
          end
        end

        def remove(plugin)
          tap do |x|
            @plugin_settings.delete_if { |p| p.class == plugin.class }
          end
        end

        def configure(xml_doc)
          xml_doc.tap do |x|
            @plugin_settings.each { |p| p.configure(x) }
          end
        end
      end
    end
  end
end
