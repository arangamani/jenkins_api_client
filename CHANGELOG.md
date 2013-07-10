CHANGELOG
=========

upcoming
--------

v0.13.0  [09-JUL-2013]
----------------------
* Jenkins XSS disable option is now supported. No inputs are required - the
  jenkins_api_client will automatically detech whether to use the crumbs or not
  when making the POST requests.
* Support for logging is added. Logs can be redirected to a log file and the
  log level can be customized. This implementation uses the `Logger` class so
  it follows the nice format in logging messages.
* The job `build` method will now optionally return the build number. This
  option should be used with care as the build method will wait till the
  jenkins job is placed on an executor from the build queue. By default the
  build number will NOT be returned. nil will be returned if the build number
  is not available. Also a Timeout error will be raised if the job waits in the
  queue for longer than the 'timeout' parameter. This timeout parameter can be
  set during the client initialization.
* Improved documentation
* Support for enabling/disabling jobs. Credit: @dieterdemeyer
* Added functionality for copying jobs. Credit: @dieterdemeyer
* Added functionality for wiping out the workspace of a job.
  Credit: @dieterdemeyer
* Added functionality for listing jenkins users. Credit: @dieterdemeyer
* Added support for SSL on Ruby 1.8.7 / JRuby 1.6. Credit: @brettporter
* Fixed a bug where the exceptions where not thrown when using the
  `get_console_output` method.
* Fixed a bug where the jenkins_path attribute was ignored when the server_url
  input argument is given. Credit: @woodbusy

v0.12.1  [25-JUN-2013]
----------------------
* Fixed a bug where the SSL support was not working properly with Ruby
  1.8.7/JRuby 1.6. Credit: @brettporter (For more info:
  https://github.com/arangamani/jenkins_api_client/pull/85)

v0.12.0  [18-JUN-2013]
----------------------
* Authentication is now optional as not all Jenkins instances have
  authentication enabled by default. Credit: @dougforpres
* Ability to retrieve build details so that more than just (`lamp color`) is
  available. Credit: @dougforpres
* Ability to retrieve build test-results for those builds that have them.
  Credit: @dougforpres
* Option to follow any 301/302 responses. This allows POST to build to follow
  the redirect and end up with a 200 response. Credit: @dougforpres
* Minor change to the POST requests handling where jenkins instances with a
  proxy returns 411 if no form data is specified. Fixed by sending an empty
  hash. Credit: @dougforpres
* As of Jenkins release 1.519, the job build returns a 201 code instead of 302.
  This was resulting in an exception and the exception handling is modified to
  handle this condition.
* The jobs that are not built yet have a new color (`notbuilt`) in the recent
  version of jenkins (> 1.517) which resulted in `invalid` status. This is fixed.

v0.11.0  [09-JUN-2013]
----------------------
* A new input argument `server_url` is supported which accepts the jenkins URL
  instead of IP address and Port. Credit: @dieterdemeyer
* When renaming the job, preserve the job history. Credit: @rubytester
* Various exception handling improvements. Credit: @drnic

v0.10.0  [24-APR-2013]
----------------------
* new function to execute jenkins CLI `cli_exec`. Credit: @missedone
* Add ability to use http proxy. Credit: @woodbusy
* prompt the user for credentials when using irb login script. @woodbusy
* bugfix for job.console_output. Credit: @drnic
* add ssl support. Credit: @madisp

v0.9.1  [01-APR-2013]
---------------------
* Removed the dependency of ActiveSupport and Builder as they were not being
  used.

v0.9.0  [10-MAR-2013]
---------------------
* Added capability to send email notification to existing jobs
* Removed warnings from client.rb
* Refactored and improved exception handling
* A bug is fixed in client which allows only the valid params as options.
  Credit: @Niarfe
* Added a timeout parameter for waiting for jenkins to become ready.
  Credit: @Niarfe
* Added function to reload jenkins. Credit: @missedone
* Fixed a bug where jenkins_path was missing in get_config and post_config.
  Credit: @cylol
* Added capability to obtain jenkins version and other useful information
* Added new tests for various cases, and other code improvements

v0.8.1  [15-FEB-2013]
---------------------
* Fixed a bug in creating view. Issue #42

v0.8.0  [14-FEB-2013]
---------------------
* Added capability to send timer trigger while creating a job
* Added rename feature for jobs
* Added support for sending skype notification in job creation and on existing
  jobs
* Added support for sending Jenkins root URL configuration. Credit: @kevinhcross
* Added `delete_all!` methods for Job, View, and Node.
* `get_eta` in BuildQueue will return "N/A" if the ETA is not given by Jenkins
* Creating view accepts params Hash and more configuration through the API
* Spaces are allowed in Job, Node, and View names. Credit: @kevinhcross
* Support has been added to build a job with parameters. Credit: @tjhanley

v0.7.3  [05-FEB-2013]
---------------------
* Fixed #27 with a bug in create_view including extra character in the end of
  the name

v0.7.2  [02-FEB-2013]
---------------------
* Fixed a minor bug in `get_console_output` of Job.

v0.7.1  [30-JAN-2013]
---------------------
* Fixed a bug (Issue #23) to remove the usage of "\" in Job.

v0.7.0  [27-JAN-2013]
---------------------
* Fixed a bug where the ignorecase was never used in view list
* Raise an error if the view doesnt exists while listing jobs
* Added capability to change the mode of a node
* Added support for giving node to restrict the job during creation
* Added support for notification_email option when setting up a job
* Added support for CVS provider in SCM
* Added `create_dump_slave` and `delete` methods in Node API
* Added BuildQueue class which is accessible by `@client.queue` method
* Improvements in all over the code for performance and error handling

v0.6.2  [13-JAN-2013]
---------------------
* Fixed a bug where running job previously aborted was not recognized by the
  color

v0.6.1  [13-JAN-2013]
---------------------
* Fixed a bug where the last few lines of console output was missed in the CLI
  when using the `jenkinscli job console` command.

v0.6.0  [12-JAN-2013]
---------------------
* Added functionality to get progressive console output from Jenkins.
* Added CLI command `console` for printing progressive console output on
  terminal.
* Fixed a bug with `get_current_build_number` not returning the recent running
  build number.

v0.5.0  [22-DEC-2012]
---------------------
* Added functionality to create jobs with params.
* Added View class and added methods accessing List Views of Jenkins server.
* Added functionality to abort a running job.
* Deprecated `list_running` of Job class. `list_by_status('running')` is
  suggested.

v0.4.0  [07-DEC-2012]
---------------------
* Added some methods for handling jobs.
* The status `not run` is not returned as `not_run` from job status.

v0.3.2  [17-NOV-2012]
---------------------
* Added some new methods for Job class

v0.3.1  [11-NOV-2012]
---------------------
* Removed unnecessary debug statements

v0.3.0  [11-NOV-2012]
---------------------
* Added System class to support quietdown and restart functionality.
* Added Node class to query the node interface of Jenkins server.
* Added Command line interface for System and Node class.
* Introduced terminal tables for displaying attributes in command line.

v0.2.1  [02-NOV-2012]
---------------------
* Added command line interface for basic operations

v0.1.1  [30-OCT-2012]
---------------------
* Updated gem dependencies to work with Ruby 1.8.7

v0.1.0  [26-OCT-2012]
---------------------
* Improved performance
* Added job create feature, delete feature, chaining feature, and build feature
* Added exception handling mechanism

v0.0.2  [16-OCT-2012]
---------------------
* Added documentation
* Added some more small features to Job class

v0.0.1  [15-OCT-2012]
---------------------
* Initial Release
