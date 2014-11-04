require File.expand_path('../../spec_helper', __FILE__)

describe JenkinsApi::Client::PluginSettings::WorkspaceCleanup do
  describe '#configure' do
    context 'given a Nokogiri::XML::Builder object' do
      let(:xml_doc) { Nokogiri::XML("<?xml version=\"1.0\"?>\n<buildWrappers>\n</buildWrappers>\n") }

      it 'adds workspace cleanup configuration to the buildWrappers' do
        workspace_cleanup_settings = JenkinsApi::Client::PluginSettings::WorkspaceCleanup.new
        workspace_cleanup_settings.configure(xml_doc)

        expect(xml_doc.at_css('buildWrappers deleteDirs').content).to eql('false')
        expect(xml_doc.at_css('buildWrappers cleanupParameter').content).to eql('')
        expect(xml_doc.at_css('buildWrappers externalDelete').content).to eql('')
      end

      it 'uses params if given' do
        workspace_cleanup_settings = JenkinsApi::Client::PluginSettings::WorkspaceCleanup.new({
          :delete_dirs => true,
          :cleanup_parameter => 'foo',
          :external_delete => 'bar',
        })
        workspace_cleanup_settings.configure(xml_doc)

        expect(xml_doc.at_css('buildWrappers deleteDirs').content).to eql('true')
        expect(xml_doc.at_css('buildWrappers cleanupParameter').content).to eql('foo')
        expect(xml_doc.at_css('buildWrappers externalDelete').content).to eql('bar')
      end
    end
  end
end
