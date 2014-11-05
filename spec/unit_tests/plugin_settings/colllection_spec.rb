require File.expand_path('../../spec_helper', __FILE__)

describe JenkinsApi::Client::PluginSettings::Collection do
  let(:plugin_settings_collection) { JenkinsApi::Client::PluginSettings::Collection.new }
  let(:plugin_setting)             { JenkinsApi::Client::PluginSettings::Base.new }

  describe '#initialize' do
    it 'raises a InvalidType exception if given anything that is not a plugin setting' do
      expect { JenkinsApi::Client::PluginSettings::Collection.new(Object.new) }.to raise_error(JenkinsApi::Client::PluginSettings::InvalidType)
    end
  end

  describe '#add' do
    context 'collection does not have member of given plugin setting' do
      it 'adds the plugin to the collection' do
        expect(plugin_settings_collection.add(plugin_setting).size).to eql(1)
      end
    end

    context 'collection alreayd has member of same tyep as given plugin setting' do
      it 'no-ops' do
        plugin_settings_collection.add(plugin_setting)
        expect(plugin_settings_collection.add(plugin_setting).size).to eql(1)
      end
    end

    it 'raises a InvalidType exception if a non plugin setting is added' do
      expect { plugin_settings_collection.add(Object.new) }.to raise_error(JenkinsApi::Client::PluginSettings::InvalidType)
    end
  end

  describe '#remove' do
    context 'collection does not have member of given plugin setting' do
      it 'no-ops' do
        expect(plugin_settings_collection.remove(plugin_setting).size).to eql(0)
      end
    end

    context 'collection already has member of same type as given plugin setting' do
      it 'removes item with same type as given plugin setting from the collection' do
        plugin_settings_collection.add(plugin_setting)
        expect(plugin_settings_collection.remove(plugin_setting).size).to eql(0)
      end
    end
  end

  describe '#configure' do
    context 'collection is empty' do
      it 'no-ops' do
        expect { plugin_settings_collection.configure(Nokogiri::XML::Document.new)}.to_not raise_error
      end
    end

    context 'collection has plugins' do
      it 'calls configure on each of its plugin members' do
        plugin_settings_collection.add(plugin_setting)
        expect(plugin_setting).to receive(:configure).once
        plugin_settings_collection.configure(Nokogiri::XML::Document.new)
      end
    end
  end
end
