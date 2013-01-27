Jenkins API Client
==================
[![Build Status](https://travis-ci.org/arangamani/jenkins_api_client.png?branch=master)](https://travis-ci.org/arangamani/jenkins_api_client)
[![Dependency Status](https://gemnasium.com/arangamani/jenkins_api_client.png)](https://gemnasium.com/arangamani/jenkins_api_client)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/arangamani/jenkins_api_client)

Copyright &copy; 2012-2013, Kannan Manickam [![endorse](http://api.coderwall.com/arangamani/endorsecount.png)](http://coderwall.com/arangamani)

Client libraries for communicating with a Jenkins CI server and programatically managing jobs.

IRC Channel: ##jenkins-api-client

Mailing list: jenkins.api.client@librelist.com

OVERVIEW:
---------
This project is a simple API client for interacting with Jenkins Continuous Integration server.
Jenkins provides three kinds of remote access API. 1. XML API, 2. JSON API, and 3. Python API.
This project aims at consuming the JSON API and provides some useful functions for controlling
jobs on the Jenkins programatically. Even though Jenkins provides an awesome UI for controlling
jobs, it would be nice and helpful to have a programmable interface so we can dynamically and
automatically manage jobs and other artifacts.

DETAILS:
--------
This projects currently only provides functionality for the <tt>jobs, node, and system</tt> interfaces.
This is still a work-in-progress project. I mainly use the functionality of this project for my autmation
work and the functionality mainly focussed on my usage and I believe others might find it useful
too. I would love to add more features to it and I will continue working on improving existing
features and add more interfaces such as nodes, views, build queue, etc,.

USAGE:
------

### Installation

Install jenkins_api_client by <tt>sudo gem install jenkins_api_client</tt>
Include this gem in your code as a require statement.

    require 'jenkins_api_client'

### Using with IRB

If you want to just play with it and not actually want to write a script, you can just use the
irb launcher script which is available in <tt>scripts/login_with_irb.rb</tt>. But make sure that
you have your credentials available in the correct location. By default the script assumes that
you have your credentials file in <tt>~/.jenkins_api_client/login.yml</tt>. If you don't prefer this
location and would like to use a different location, just modify that script to point to the
location where the credentials file exists.

    ruby scripts/login_with_irb.rb

You will see the that it entered IRB session and you can play with the API client with the
<tt>@client</tt> object that it has returned.

### Authentication

This project supports two types of password-based authentication. You can just you the plain
password by using <tt>password</tt> parameter. If you don't prefer leaving plain passwords in the
credentials file, you can encode your password in base64 format and use <tt>password_base64</tt>
parameter to specify the password either in the arguments or in the credentials file.

### Basic Usage

As discussed earlier, you can either specify all the credentials and server information as
parameters to the Client or have a credentials file and just parse the yaml file and pass it in.
The following call just passes the information as parameters

```ruby
@client = JenkinsApi::Client.new(:server_ip => '0.0.0.0',
         :username => 'somename', :password => 'secret password')
# The following call will return all jobs matching 'Testjob'
puts @client.job.list("^Testjob")
```

The following example passes the YAML file contents. An example yaml file is located in
<tt>config/login.yml.example</tt>.

```ruby
@client = JenkinsApi::Client.new(YAML.Load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))
# The following call lists all jobs
puts @client.job.list_all
```

### Chaining and Building Jobs

Sometimes we want certain jobs to be added as downstream projects and run them sequencially.
The following example will explain how this could be done.

```ruby
require 'jenkins_api_client'

# We want to filter all jobs that start with 'test_job'
# Just write a regex to match all the jobs that start with 'test_job'
jobs_to_filter = "^test_job.*"

# Create an instance to jenkins_api_client
@client = JenkinsApi::Client.new(YAML.load_file(File.expand_path('~/.jenkins_api_client/login.yml', __FILE__)))

# Get a filtered list of jobs from the server
jobs = @client.job.list(jobs_to_filter)

# Chain all the jobs with 'success' as the threshold
# The chain method will return the jobs that is in the head of the sequence
# This method will also remove any existing chaining
initial_jobs = @client.job.chain(jobs, 'success', ["all"])

# Now that we have the initial job(s) we can build them
# The build function returns a code from the API which should be 302 if the build was successful
code = @client.job.build(initial_jobs[0])
raise "Could not build the job specified" unless code == 302
```

In the above example, you might have noticed that the chain method returns an array instead of a
single job. There is a reason behind it. In simple chain, such as the one in the example above, all
jobs specified are chained one by one. But in some cases they might not be dependent on the previous
jobs and we might want to run some jobs parallelly. We just have to specify that as a parameter.

For example: <tt>parallel = 3</tt> in the parameter list to the <tt>chain</tt> method will take the first three
jobs and chain them with the next three jobs and so forth till it reaches the end of the list.

There is another filter option you can specify for the method to take only jobs that are in a
particular state. In case if we want to build only jobs that are failed or unstable, we can achieve
that by passing in the states in the third parameter. In the example above, we wanted build all jobs.
If we just want to build failed and unstable jobs, just pass <tt>["failure", "unstable"]</tt>. Also if you
pass in an empty array, it will assume that you want to consider all jobs and no filtering will be
performed.

There is another parameter called <tt>threshold</tt> you can specify for the chaining and this is used
to decide whether to move forward with the next job in the chain or not. A <tt>success</tt> will move to
the next job only if the current build succeeds, <tt>failure</tt> will move to the next job even if the build
fails, and <tt>unstable</tt> will move to the job even if the build is unstable.

The following call to the <tt>chain</tt> method will consider only failed and unstable jobs, chain then
with 'failure' as the threshold, and also chain three jobs in parallel.

```ruby
initial_jobs = @client.job.chain(jobs, 'failure', ["failure", "unstable"], 3)
# We will receive three jobs as a result and we can build them all
initial_jobs.each { |job|
  code = @client.job.build(job)
  raise "Unable to build job: #{job}" unless code == 302
}
```

### Using with command line
Command line interface is supported only from version 0.2.0.
See help using <tt>jenkinscli help</tt>

There are three ways for authentication using command line interface
1. Passing all credentials and server information using command line parameters
2. Passing the credentials file as the command line parameter
3. Having the credentials file in the default location <tt>HOME/.jenkins_api_client/login.yml</tt>

### Debug

The call to client initialization accepts a debug parameter. If it is set to <tt>true</tt> it will print
some debug information to the console. By default it is set to false.

CONTRIBUTING:
-------------

If you would like to contribute to this project, just do the following:

1. Fork the repo on Github.
2. Add your features and make commits to your forked repo.
3. Make a pull request to this repo.
4. Review will be done and changes will be requested.
5. Once changes are done or no changes are required, pull request will be merged.
6. The next release will have your changes in it.

FEATURE REQUEST:
----------------

If you use this gem for your project and you think it would be nice to have a particular feature
that is presently not implemented, I would love to hear that and consider working on it.
Just open an issue in Github as a feature request.
