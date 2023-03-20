Jenkins API Client
==================

[![Gem Version](http://img.shields.io/gem/v/jenkins_api_client.svg)][gem]
[![Build Status](http://img.shields.io/travis/arangamani/jenkins_api_client.svg)][travis]
[![Dependency Status](http://img.shields.io/gemnasium/arangamani/jenkins_api_client.svg)][gemnasium]
[![Code Climate](http://img.shields.io/codeclimate/github/arangamani/jenkins_api_client.svg)][codeclimate]

[gem]: https://rubygems.org/gems/jenkins_api_client
[travis]: http://travis-ci.org/arangamani/jenkins_api_client
[gemnasium]: https://gemnasium.com/arangamani/jenkins_api_client
[codeclimate]: https://codeclimate.com/github/arangamani/jenkins_api_client

Copyright &copy; 2012-2017, Kannan Manickam [![endorse](http://api.coderwall.com/arangamani/endorsecount.png)](http://coderwall.com/arangamani)

Client libraries for communicating with a Jenkins CI server and programatically managing jobs.

IRC Channel: ##jenkins-api-client (on freenode)

Mailing list: jenkins_api_client@googlegroups.com

Google Group: https://groups.google.com/group/jenkins_api_client

OVERVIEW:
---------
This project is a simple API client for interacting with Jenkins Continuous
Integration server. Jenkins provides three kinds of remote access API.
1. XML API, 2. JSON API, and 3. Python API. This project aims at consuming the
JSON API and provides some useful functions for controlling jobs on the Jenkins
programatically. Even though Jenkins provides an awesome UI for controlling
jobs, it would be nice and helpful to have a programmable interface so we can
dynamically and automatically manage jobs and other artifacts.

DETAILS:
--------
This projects currently only provides functionality for the
<tt>jobs, node, view, system, and build queue</tt> interfaces.

USAGE:
------

### Installation

Install jenkins_api_client by <tt>sudo gem install jenkins_api_client</tt>
Include this gem in your code as a require statement.

    require 'jenkins_api_client'

### Using with IRB

If you want to just play with it and not actually want to write a script, you
can just use the irb launcher script which is available in
<tt>scripts/login_with_irb.rb</tt>. But make sure that you have your credentials
available in the correct location. By default the script assumes that you have
your credentials file in <tt>~/.jenkins_api_client/login.yml</tt>. If you don't
prefer this location and would like to use a different location, just modify
that script to point to the location where the credentials file exists.

    ruby scripts/login_with_irb.rb

You will see the that it entered IRB session and you can play with the API
client with the <tt>@client</tt> object that it has returned.

### Authentication

Supplying credentials to the client is optional, as not all Jenkins instances
require authentication. This project supports two types of password-based
authentication. You can just you the plain password by using <tt>password</tt>
parameter. If you don't prefer leaving plain passwords in the credentials file,
you can encode your password in base64 format and use <tt>password_base64</tt>
parameter to specify the password either in the arguments or in the credentials
file. To use the client without credentials, just leave out the
<tt>username</tt> and <tt>password</tt> parameters. The <tt>password</tt>
parameter is only required if <tt>username</tt> is specified.

#### Using with Open ID

It is very simple to authenticate with your Jenkins server that has Open ID
authentication enabled. You will have to obtain your API token and use the API
token as the password. For obtaining the API token, go to your user configuration
page and click 'Show API Token'. Use this token for the `password` parameter when
initializing the client.

### Cross-site Scripting (XSS) and Crumb Support

Support for Jenkins crumbs has been added.  These allow an application to
use the Jenkins API POST methods without requiring the 'Prevent Cross Site
Request Forgery exploits' to be disabled.  The API will check in with the
Jenkins server to determine whether crumbs are enabled or not, and use them
if appropriate.

### SSL certificate verification

When connecting over HTTPS if the server's certificate is not trusted the
connection will be aborted. To trust a certificate specify the `ca_file`
parameter when creating the client. The value should be a path to a PEM encoded
file containing the certificates.

### Basic Usage

As discussed earlier, you can either specify all the credentials and server
information as parameters to the Client or have a credentials file and just
parse the yaml file and pass it in. The following call just passes the
information as parameters

```ruby
@client = JenkinsApi::Client.new(:server_ip => '0.0.0.0',
         :username => 'somename', :password => 'secret password')
# The following call will return all jobs matching 'Testjob'
puts @client.job.list("^Testjob")
```

The following example passes the YAML file contents. An example yaml file is
located in <tt>config/login.yml.example</tt>.

```ruby
@client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(
  "~/.jenkins_api_client/login.yml", __FILE__)))
# The following call lists all jobs
puts @client.job.list_all
```

### Chaining and Building Jobs

Sometimes we want certain jobs to be added as downstream projects and run them
sequentially. The following example will explain how this could be done.

```ruby
require 'jenkins_api_client'

# We want to filter all jobs that start with 'test_job'
# Just write a regex to match all the jobs that start with 'test_job'
jobs_to_filter = "^test_job.*"

# Create an instance to jenkins_api_client
@client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(
  "~/.jenkins_api_client/login.yml", __FILE__)))

# Get a filtered list of jobs from the server
jobs = @client.job.list(jobs_to_filter)

# Chain all the jobs with 'success' as the threshold
# The chain method will return the jobs that is in the head of the sequence
# This method will also remove any existing chaining
initial_jobs = @client.job.chain(jobs, 'success', ["all"])

# Now that we have the initial job(s) we can build them
# The build function returns a code from the API which should be 201 if
# the build was successful, for Jenkins >= v1.519
# For versions older than v1.519, the success code is 302.
code = @client.job.build(initial_jobs[0])
raise "Could not build the job specified" unless code == '201'
```

In the above example, you might have noticed that the chain method returns an
array instead of a single job. There is a reason behind it. In simple chain,
such as the one in the example above, all jobs specified are chained one by
one. But in some cases they might not be dependent on the previous jobs and we
might want to run some jobs parallelly. We just have to specify that as a
parameter.

For example: <tt>parallel = 3</tt> in the parameter list to the <tt>chain</tt>
method will take the first three jobs and chain them with the next three jobs
and so forth till it reaches the end of the list.

There is another filter option you can specify for the method to take only
jobs that are in a particular state. In case if we want to build only jobs
that are failed or unstable, we can achieve that by passing in the states in
the third parameter. In the example above, we wanted build all jobs. If we just
want to build failed and unstable jobs, just pass
<tt>["failure", "unstable"]</tt>. Also if you pass in an empty array, it will
assume that you want to consider all jobs and no filtering will be performed.

There is another parameter called <tt>threshold</tt> you can specify for the
chaining and this is used to decide whether to move forward with the next job
in the chain or not. A <tt>success</tt> will move to the next job only if the
current build succeeds, <tt>failure</tt> will move to the next job even if the
build fails, and <tt>unstable</tt> will move to the job even if the build is
unstable.

The following call to the <tt>chain</tt> method will consider only failed and
unstable jobs, chain then with 'failure' as the threshold, and also chain three
jobs in parallel.

```ruby
initial_jobs = @client.job.chain(jobs, 'failure', ["failure", "unstable"], 3)
# We will receive three jobs as a result and we can build them all
initial_jobs.each do |job|
  code = @client.job.build(job)
  raise "Unable to build job: #{job}" unless code == '201'
end
```

### Configuring plugins

Given the abundance of plugins for Jenkins, we now provide a extensible way to 
setup jobs and configure their plugins. Right now, the gem ships with the hipchat
plugin, with more plugins to follow in the future. 

```ruby
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

client = JenkinsApi::Client.new(
  server_url: jenkins_server,
  username: username,
  password: password
)

# NOTE: plugins can be splatted so if you had another plugin it could be passed
# to the new call below as another arg after hipchat
job = JenkinsApi::Client::Job.new(client, hipchat)

```

Writing your own plugins is also straightforward. Inherit from the 
JenkinsApi::Client::PluginSettings::Base class and override the configure method.
Jenkins jobs are configured using xml so you just nee to figure out where in the
configuration to hook in your plugin settings.

Here is an example of a plugin written to configure a job for workspace cleanup.  

```ruby
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
        # @param xml_doc [Nokogiri::XML::Document] xml document to be updated with 
        # the plugin configuration
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
```

Currently, the skype plugin is still configured directly on the jenkins job. This will 
likely be extracted into its own plugin in the near future, but we will maintain 
backwards compatibility until after an official deprecation period.

### Waiting for a build to start/Getting the build number
Newer versions of Jenkins (starting with the 1.519 build) make it easier for
an application to determine the build number for a 'build' request. (previously
there would be a degree of guesswork involved).  The new version actually
returns information allowing the jenkins_api_client to check the build queue
for the job and see if it has started yet (once it has started, the build-
number is available.

If you wish to take advantage of this hands-off approach, the build method
supports an additional 'opts' hash that lets you specify how long you wish to
wait for the build to start.

#### Old Jenkins vs New Jenkins (1.519+)

##### Old (v < 1.519)
The 'opts' parameter will work with older versions of Jenkins with the following
caveats:
* The 'cancel_on_build_start_timeout' option has no effect
* The build_number is calculated by calling 'current_build_number' and adding
  1 before the build is started.  This might break if there are multiple
  entities running builds on the same job, or there are queued builds.

##### New (v >= 1.519)
* All options work, and build number is accurately determined from queue
  info.
* The build trigger success code is now 201 (Created). Previously it was 302.

#### Initiating a build and returning the build_number

##### Minimum required
```ruby
# Minimum options required
opts = {'build_start_timeout' => 30}
@client.job.build(job_name, job_params || {}, opts)
```
This method will block for up to 30 seconds, while waiting for the build to
start.  Instead of returning an http-status code, it will return the
build_number, or if the build has not started will raise 'Timeout::Error'
Note: to maintain legacy compatibility, passing 'true' will set the timeout
to the default timeout specified when creating the @client.

##### Auto cancel the queued-build on timeout
```ruby
# Wait for up to 30 seconds, attempt to cancel queued build
opts = {'build_start_timeout' => 30,
        'cancel_on_build_start_timeout' => true}
@client.job.build(job_name, job_params || {}, opts)
```
This method will block for up to 30 seconds, while waiting for the build to
start.  Instead of returning an http-status code, it will return the
build_number, or if the build has not started will raise 'Timeout::Error'.
Prior to raising the Timeout::Error, it will attempt to cancel the queued
build - thus preventing it from starting.

##### Getting some feedback while you're waiting
The opts parameter supports two values that can be assigned proc objects
(which will be 'call'ed).  Both are optional, and will only be called if
specified in opts.
These are initially intended to assist with logging progress.

* 'progress_proc' - called when job is initially queued, and periodically
  thereafter.
  * max_wait - the value of 'build_start_timeout'
  * current_wait - how long we've been waiting so far
  * poll_count - how many times we've polled the queue
* 'completion_proc' - called just prior to return/Timeout::Error
  * build_number - the build number assigned (or nil if timeout)
  * cancelled - whether the build was cancelled (true if 'new' Jenkins
    and it was able to cancel the build, false otherwise)

To use a class method, just specify 'instance.method(:method_name)', or
use a proc or lambda

```ruby
# Wait for up to 30 seconds, attempt to cancel queued build, progress
opts = {'build_start_timeout' => 30,
        'cancel_on_build_start_timeout' => true,
        'poll_interval' => 2,      # 2 is actually the default :)
        'progress_proc' => lambda {|max,curr,count| ... },
        'completion_proc' => lambda {|build_number,cancelled| ... }}
@client.job.build(job_name, job_params || {}, opts)
```
### Running Jenkins CLI
To running [Jenkins CLI](https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI)

* authentication with username/password (deprecated)

```ruby
@client = JenkinsApi::Client.new(:server_ip => '127.0.0.1',
         :username => 'somename', :password => 'secret password')
# The following call will return the version of Jenkins instance
puts @client.exec_cli("version")
```

* authentication with public/private key file
remember to upload the public key to:

    `http://#{Server IP}:#{Server Port}/user/#{Username}/configure`

```ruby
@client = JenkinsApi::Client.new(:server_ip => '127.0.0.1',
         :identity_file => '~/.ssh/id_rsa')
# The following call will return the version of Jenkins instance
puts @client.exec_cli("version")
```

Before you run the CLI, please make sure the following requirements are
fulfilled:
* JRE/JDK 6 (or above) is installed, and 'java' is on the $PATH environment
  variable
* The ```jenkins_api_client/java_deps/jenkins-cli.jar``` is required as the
  client to run the CLI. You can retrieve the available commands via accessing
  the URL: ```http://<server>:<port>/cli```
* (Optional) required if you run the Groovy Script through CLI, make sure
  the *user* have the privilige to run script

### Using with command line
Command line interface is supported only from version 0.2.0.
See help using <tt>jenkinscli help</tt>

There are three ways for authentication using command line interface
1. Passing all credentials and server information using command line parameters
2. Passing the credentials file as the command line parameter
3. Having the credentials file in the default location
   <tt>HOME/.jenkins_api_client/login.yml</tt>

### Debug

As of v0.13.0, this debug parameter is removed. Use the logger instead. See the
next section for more information about this option.

### Logger

As of v0.13.0, support for logger is introduced. Since it would be nice to have
the activities of the jenkins_api_client in a log file, this feature is
implemented using the Ruby's standard Logger class. For using this feature,
there are two new input arguments used during the initialization of Client.

1. `:log_location` - This argument specifies the location for the log file. A
   good location for linux based systems would be
   '/var/log/jenkins_api_client.log'. The default for this values is STDOUT.
   This will print the log messages on the console itself.
2. `:log_level` - This argument specifies the level of messages to be logged.
   It should be one of Logger::DEBUG (0), Logger::INFO (1), Logger::WARN (2),
   Logger::ERROR (3), Logger::FATAL (4). It can be specified either using the
   constants available in the Logger class or using these integers provided
   here. The default for this argument is Logger::INFO (1)

If you want customization on the functionality Logger provides such as leave n
old log files, open the log file in append mode, create your own logger and
then set that in the client.

#### Examples

```ruby
  @client = JenkinsApi::Client.new(...)
  # Create a logger which ages logfile once it reaches a certain size. Leave 10
  # “old log files” and each file is about 1,024,000 bytes.
  @client.logger = Logger.new('foo.log', 10, 1024000)
```
Please refer to [Ruby
Logger](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html)
for more information.

CONTRIBUTING:
-------------

If you would like to contribute to this project, just do the following:

1. Fork the repo on Github.
2. Add your features and make commits to your forked repo.
3. Make a pull request to this repo.
4. Review will be done and changes will be requested.
5. Once changes are done or no changes are required, pull request will be merged.
6. The next release will have your changes in it.

Please take a look at the issues page if you want to get started.

FEATURE REQUEST:
----------------

If you use this gem for your project and you think it would be nice to have a
particular feature that is presently not implemented, I would love to hear that
and consider working on it. Just open an issue in Github as a feature request.
