module JenkinsApi
  class Client
    module PluginSettings
      class Hipchat < Base

        # @option params [String] :room
        #   id of the room
        # @option params [Boolean] :start_notification (false)
        #   whether to notify room when build starts
        # @option params [Boolean] :notify_success (false)
        #   whether to notify room when build succeeds
        # @option params [Boolean] :notify_aborted (false)
        #   whether to notify room when build aborts
        # @option params [Boolean] :notify_not_built (false)
        #   whether to notify room when job could not be build
        # @option params [String] :notify_unstable
        #   whether to notify room when job becomes unstable
        # @option params [String] :notify_failure
        #   whether to notify room when job fails
        # @option params [String] :notify_back_to_normal
        #   whether to notify room when job becomes stable
        # 
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
            Nokogiri::XML::Builder.with(doc.at('properties')) do |properties|
              properties.send('jenkins.plugins.hipchat.HipChatNotifier_-HipChatJobProperty') do |x|
                x.room @params.fetch(:room) { '' }
                x.startNotification @params.fetch(:start_notification) { false }
                x.notifySuccess @params.fetch(:notify_success) { false }
                x.notifyAborted @params.fetch(:notify_aborted) { false }
                x.notifyNotBuilt @params.fetch(:notify_not_built) { false }
                x.notifyUnstable @params.fetch(:notify_unstable) { false }
                x.notifyFailure @params.fetch(:notify_failure) { false }
                x.notifyBackToNormal @params.fetch(:notify_back_to_normal) { false }
              end
            end
          end
        end
      end
    end
  end
end
