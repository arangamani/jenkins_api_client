module JenkinsApi
  class Client
    module PluginSettings
      class WorkspaceCleanup < Base

        # @option params [Boolean] :delete_dirs (false)
        #   whether to also apply pattern on directories
        # @option params [String] :cleanup_parameters
        # @option params [String] :external_delete
        def initialize(params={})
          @params = params
        end

        # Create or Update a job with params given as a hash instead of the xml
        # This gives some flexibility for creating/updating simple jobs so the
        # user doesn't have to learn about handling xml.
        #
        # @param xml_doc [Nokogiri::XML::Document] xml document to be updated with the plugin configuration
        #
        # @return [Nokogiri::XML::Document]
        def configure(xml_doc)
          xml_doc.tap do |doc|
            Nokogiri::XML::Builder.with(doc.at('buildWrappers')) do |build_wrappers|
              build_wrappers.send('hudson.plugins.ws__cleanup.PreBuildCleanup') do |x|
                x.deleteDirs @params.fetch(:delete_dirs) { false }
                x.cleanupParameter @params.fetch(:cleanup_parameter) { '' }
                x.externalDelete @params.fetch(:external_delete) { '' }
              end
            end
          end
        end
      end
    end
  end
end
