lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jenkins_api_client/version'

Gem::Specification.new do |s|
  s.name = "jenkins_api_client"
  s.version = ::JenkinsApi::Client::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Kannan Manickam"]
  s.description = "\nThis is a simple and easy-to-use Jenkins Api client with features focused on\nautomating Job configuration programaticaly and so forth"
  s.email = ["arangamani.kannan@gmail.com"]
  s.executables = ['jenkinscli']
  s.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r{lib/|bin/|java_deps/|gemspec}) }
  s.require_paths = ['lib']
  s.homepage = 'https://github.com/arangamani/jenkins_api_client'
  s.required_ruby_version = ::Gem::Requirement.new('~> 2.1')
  s.rubygems_version = "2.4.5.1"
  s.summary = "Jenkins JSON API Client"
  s.licenses = ["MIT"]

  s.add_dependency 'nokogiri', '~> 1.6'
  s.add_dependency 'thor', '>= 0.16.0'
  s.add_dependency 'terminal-table', '>= 1.4.0'
  s.add_dependency 'mixlib-shellout', '~> 2.0.0'
  s.add_dependency 'socksify', '>= 1.7.0'
  s.add_dependency 'json', '>= 1.0'
end
