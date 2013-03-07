Gem::Specification.new do |s|
  s.name = "jenkins_api_client"
  s.version = "0.8.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kannan Manickam"]
  s.date = "2013-02-15"
  s.description = "\nThis is a simple and easy-to-use Jenkins Api client with features focused on\nautomating Job configuration programaticaly and so forth"
  s.email = ["arangamani.kannan@gmail.com"]
  s.executables = ["jenkinscli"]
  s.files = ["bin/jenkinscli"]
  s.homepage = "https://github.com/arangamani/jenkins_api_client"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Jenkins JSON API Client"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.2.8"])
      s.add_runtime_dependency(%q<thor>, [">= 0.16.0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<terminal-table>, [">= 1.4.0"])
      s.add_runtime_dependency(%q<builder>, ["~> 3.1.3"])
      s.add_development_dependency(%q<bundler>, [">= 1.0"])
      s.add_development_dependency(%q<jeweler>, [">= 1.6.4"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<activesupport>, ["~> 3.2.8"])
      s.add_dependency(%q<thor>, [">= 0.16.0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<terminal-table>, [">= 1.4.0"])
      s.add_dependency(%q<builder>, ["~> 3.1.3"])
      s.add_dependency(%q<bundler>, [">= 1.0"])
      s.add_dependency(%q<jeweler>, [">= 1.6.4"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<activesupport>, ["~> 3.2.8"])
    s.add_dependency(%q<thor>, [">= 0.16.0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<terminal-table>, [">= 1.4.0"])
    s.add_dependency(%q<builder>, ["~> 3.1.3"])
    s.add_dependency(%q<bundler>, [">= 1.0"])
    s.add_dependency(%q<jeweler>, [">= 1.6.4"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
