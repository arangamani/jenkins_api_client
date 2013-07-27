lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jenkins_api_client/version'
require 'rake'
require 'jeweler'
require 'yard'

Jeweler::Tasks.new do |gemspec|
  gemspec.name             = 'jenkins_api_client'
  gemspec.version          = JenkinsApi::Client::VERSION
  gemspec.platform         = Gem::Platform::RUBY
  gemspec.date             = Time.now.utc.strftime("%Y-%m-%d")
  gemspec.require_paths    = ["lib"]
  gemspec.executables      = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gemspec.files            = `git ls-files`.split("\n")
  gemspec.extra_rdoc_files = ['CHANGELOG.rdoc', 'LICENSE', 'README.rdoc']
  gemspec.authors          = [ 'Kannan Manickam' ]
  gemspec.email            = [ 'arangamani.kannan@gmail.com' ]
  gemspec.homepage         = 'https://github.com/arangamani/jenkins_api_client'
  gemspec.summary          = 'Jenkins JSON API Client'
  gemspec.description      = %{
This is a simple and easy-to-use Jenkins Api client with features focused on
automating Job configuration programaticaly and so forth}
  gemspec.test_files = `git ls-files -- {spec}/*`.split("\n")
  gemspec.rubygems_version = '1.8.17'
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:unit_tests) do |spec|
  spec.pattern = FileList['spec/unit_tests/*_spec.rb']
  spec.rspec_opts = ['--color', '--format documentation']
end

RSpec::Core::RakeTask.new(:func_tests) do |spec|
  spec.pattern = FileList['spec/func_tests/*_spec.rb']
  spec.rspec_opts = ['--color', '--format documentation']
end

RSpec::Core::RakeTask.new(:test) do |spec|
  spec.pattern = FileList['spec/*/*.rb']
  spec.rspec_opts = ['--color', '--format documentation']
end

YARD::Config.load_plugin 'thor'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', 'lib/**/**/*.rb']
end

# This task requires that graphviz is installed locally. For more info:
# http://www.graphviz.org/
desc "Generates the class diagram using the yard generated dot file"
task :generate_class_diagram do
  puts "Generating the dot file..."
  `yard graph --file jenkins_api_client.dot`
  puts "Generating class diagram from the dot file..."
  `dot jenkins_api_client.dot -Tpng -o jenkins_api_client_class_diagram.png`
end

task :default => [:unit_tests]
