CHANGELOG
=========

upcoming
--------

v0.8.0  [14-FEB-2013]
---------------------
* Added capability to send timer trigger while creating a job
* Added rename feature for jobs
* Added support for sending skype notification in job creation and on existing jobs
* Added support for sending Jenkins root URL configuration. Credit: @kevinhcross
* Added `delete_all!` methods for Job, View, and Node.
* `get_eta` in BuildQueue will return "N/A" if the ETA is not given by Jenkins
* Creating view accepts params Hash and more configuration through the API
* Spaces are allowed in Job, Node, and View names. Credit: @kevinhcross
* Support has been added to build a job with parameters. Credit: @tjhanley

v0.7.3  [05-FEB-2013]
---------------------
* Fixed #27 with a bug in create_view including extra character in the end of the name

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
* Fixed a bug where running job previously aborted was not recognized by the color

v0.6.1  [13-JAN-2013]
---------------------
* Fixed a bug where the last few lines of console output was missed in the CLI when using the `jenkinscli job console` command.

v0.6.0  [12-JAN-2013]
---------------------
* Added functionality to get progressive console output from Jenkins.
* Added CLI command `console` for printing progressive console output on terminal.
* Fixed a bug with `get_current_build_number` not returning the recent running build number.

v0.5.0  [22-DEC-2012]
---------------------
* Added functionality to create jobs with params.
* Added View class and added methods accessing List Views of Jenkins server.
* Added functionality to abort a running job.
* Deprecated `list_running` of Job class. `list_by_status('running')` is suggested.

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
