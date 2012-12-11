require File.join([File.dirname(__FILE__),'lib','jenkins_api_client/version.rb'])

Gem::Specification.new do |s|
  s.name        = "jenkins_api_client"
  s.version     = JenkinsApi::Client::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date         = Time.now.utc.strftime("%Y-%m-%d")
  s.require_path = 'lib'
  s.executables  = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  s.files        = `git ls-files`.split("\n")
  #s.extra_rdoc_files = ['CHANGELOG.rdoc', 'LICENSE', 'README.rdoc']
  s.authors      = [ 'Kannan Manickam' ]
  s.email        = [ 'arangamani.kannan@gmail.com' ]
  s.homepage     = 'https://github.com/arangamani/jenkins_api_client'
  s.summary      = 'Jenkins JSON API Client'
  s.description  = %{
This is a simple and easy-to-use Jenkins Api client with features focused on
automating Job configuration programaticaly and so forth}
  s.test_files = `git ls-files -- {spec}/*`.split("\n")
  s.rubygems_version = '1.8.17'

  s.add_runtime_dependency('nokogiri')
  s.add_runtime_dependency('activesupport', '~> 3.2.8')
  s.add_runtime_dependency('thor', '~> 0.16.0')
  s.add_runtime_dependency('json', '>= 0')
  s.add_runtime_dependency('terminal-table', '>= 1.4.0')
end
