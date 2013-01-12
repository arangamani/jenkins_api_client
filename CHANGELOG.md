CHANGELOG
=========

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
* Added some more smal features to Job class

v0.0.1  [15-OCT-2012]
---------------------
* Initial Release
