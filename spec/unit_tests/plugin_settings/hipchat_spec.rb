require File.expand_path('../../spec_helper', __FILE__)

describe JenkinsApi::Client::PluginSettings::Hipchat do
  describe '#configure' do
    context 'given a Nokogiri::XML::Builder object' do
      it 'adds hipchat configuration to the properties tag with default opts' do
        hipchat_settings = JenkinsApi::Client::PluginSettings::Hipchat.new
        hipchat_settings.configure(xml_doc=Nokogiri::XML("<?xml version=\"1.0\"?>\n<properties>\n</properties>\n"))

        expect(xml_doc.at_css('properties room').content).to eql('')
        expect(xml_doc.at_css('properties startNotification').content).to eql('false')
        expect(xml_doc.at_css('properties notifySuccess').content).to eql('false')
        expect(xml_doc.at_css('properties notifyAborted').content).to eql('false')
        expect(xml_doc.at_css('properties notifyNotBuilt').content).to eql('false')
        expect(xml_doc.at_css('properties notifyUnstable').content).to eql('false')
        expect(xml_doc.at_css('properties notifyFailure').content).to eql('false')
        expect(xml_doc.at_css('properties notifyBackToNormal').content).to eql('false')
      end

      it 'uses params if given' do
        hipchat_settings = JenkinsApi::Client::PluginSettings::Hipchat.new({
          :room => '10000',
          :start_notification => true,
          :notify_success => true,
          :notify_aborted => true,
          :notify_not_built => true,
          :notify_unstable => true,
          :notify_failure => true,
          :notify_back_to_normal => true,
        })
        hipchat_settings.configure(xml_doc=Nokogiri::XML("<?xml version=\"1.0\"?>\n<properties>\n</properties>\n"))

        expect(xml_doc.at_css('properties room').content).to eql('10000')
        expect(xml_doc.at_css('properties startNotification').content).to eql('true')
        expect(xml_doc.at_css('properties notifySuccess').content).to eql('true')
        expect(xml_doc.at_css('properties notifyAborted').content).to eql('true')
        expect(xml_doc.at_css('properties notifyNotBuilt').content).to eql('true')
        expect(xml_doc.at_css('properties notifyUnstable').content).to eql('true')
        expect(xml_doc.at_css('properties notifyFailure').content).to eql('true')
        expect(xml_doc.at_css('properties notifyBackToNormal').content).to eql('true')
      end
    end
  end
end
