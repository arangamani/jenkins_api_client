CHANGELOG
=========

upcoming
--------

v1.4.4   [09-SEP-2016]
----------------------
* [#213][] Add support for getting a user's API token.

v1.4.3   [07-JUN-2016]
----------------------
* [#207][] Add support for SOCKS proxies. Credit: [@dylanmckay][]

v1.4.2   [25-OCT-2015]
----------------------
* [#188][] Added ability view jobs in a view with details. Credit: [@Tyrael][]

v1.4.1   [21-SEP-2015]
----------------------
* [#191][] Add dynamic depth support for node attributes. Credit: [@stjohnjohnson][]

v1.4.0   [08-JUN-2015]
----------------------
* [#161][] Fix job#build method when true/false values are passed as timeout parameter. Credit: [@jlucasps][]
* [#172][] Promotion plugin config support. Credit: [@AndrewHanes][]
* [#168][] Added ability to pass "tree" parameter to the Job#get_builds call. Credit: [@bkon][]
* [#169][] Add optional parameters to cli job build. Credit: [@cyrez][]
* [#167][] Add ability to override the default logger. Credit: [@gpetras][]
* [#174][] Use the specified client ssl when downloading artifacts. Credit: [@paulgeringer][]
* [#165][] Fix for is_offline? bug reporting all nodes as being offline. Credit: [@bsnape][]
* [#176][] Add ability to delete a promotion configuration. Credit: [@l8nite][]
* [#59][] Add capability to take the node offline and online. Credit: [@stjohnjohnson][]
* [#177][] Add ability to create promotion processes. Credit: [@AndrewHanes][]
* [#179][] Clean up Node calls to make only one call for the computer item. Credit: [@stjohnjohnson][]

v1.3.0   [03-JAN-2015]
----------------------
* [#159][] Add ability to configure git tool for a job. Credit: [@hubert][]
* [#163][] Improve performance by using the `tree` parameter. Credit: [@stjohnjohnson][]

v1.2.0   [12-NOV-2014]
----------------------
* [#156][] Added workspace cleanup plugin. Credit [@hubert][]
* [#157][] Added ability to configure SCM trigger via job creation. Credit: [@hubert][]
* [#158][] Add ability to configure post build artifact archiver step. Credit: [@hubert][]

v1.1.0   [05-NOV-2014]
----------------------
* [#145][] Fix `BuildQueue#get_details` to compare against task_name. Credit: [@notruthless][]
* [#149][] Lower log level of GET/POST messages emitted by Client to DEBUG. Credit: [@scotje][]
* [#151][] Add ability to configure credentialId for git. Credit: [@hubert][]
* [#153][] Feature/extract plugins. Credit: [@hubert][]
* [#147][] Added ability to get current build artifact. Credit: [@joelneubert][]
* [#148][] Make `Client::Job#build` only request current build number if `build_start_timeout` option is passed.
  Credit: [@scotje][]

v1.0.1   [16-JUL-2014]
----------------------
* Add `charset=UTF-8` along with content_type when posting data to Jenkins.

v1.0.0   [23-JUN-2014]
----------------------
* Ruby 1.8 is not supported anymore.
* Added support for `PluginManager` which supports listing installed plugins,
  available plugins, installing and uninstalling plugins, enabling and disabling
  plugins, and more.
* Enhance URL escape.
* [#106][] Added support for obtaining build numbers after the build is posted for Jenkins
  version pre 1.519, added callbacks while waiting and more. Credit: [@dougforpres][]
* [#112][] Added supported for obtaining information about promoted builds. Credit: [@dkerwin][]
* [#118][] Added support for specifying username/password in the URL. Credit: [@spikegrobstein][]
* [#119][] Added ability to execute groovy script on the Jenkins server. Credit: [@lheinlen-os][]
* [#122][] Updated the `create_dumb_slave` method to accept the new credentials id that is
  introduced in the newer version of jenkins. Credit: [@Loa][]
* [#126][] Enabled the use of cookies for authentication. Credit: [@chilicheech][]
* [#127][] Do not set content type in api_post_request. Credit: [@chilicheech][]
* [#128][] Updated `exec_script` to use `api_post_reqeust` to support features provided by
  `api_post_request` such as using crumbs. Credit: [@chilicheech][]
* [#132][] Allow copying and enabling jobs with spaces in them. Credit: [@mattrose][]
* [#134][] Added support for specifying HTTP open timeout. Credit: [@n-rodriguez][]
* [#136][] Prevent warnings due to Hash#[] call with nil items on Ruby 2.x. Credit: [@sunaot][]
* [#140][] Add require yaml in cli helper. Credit: [@riywo][]
* [#141][] Rename `create_dump_slave` -> `create_dumb_slave`. Thanks for finding the
  typo/incorrect name [@cynipe][]


v0.14.1  [18-AUG-2013]
----------------------
* Fixed a bug in Job#create_or_update method. Credit: [@bobbrez][]

v0.14.0  [07-AUG-2013]
----------------------
* Fixed a bug where a space was missing in the exec_cli method argument list.
  Credit: [@missedone][]
* Refactored create/update jobs by introducing create_or_update methods.
  Credit: [@riywo][]
* Enhancement to crumb processing - auto detect the change of crumb setting and
  do proper exception handling. Credit: dougforpress
* Added a `User` class which will handle jenkins users related functions.
  Credit: dougforpres
* Added a method `Job#poll` which will poll for SCM changes programatically.
* Added a shortcut method `System#restart!` for force restart.

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
* Support for enabling/disabling jobs. Credit: [@dieterdemeyer][]
* Added functionality for copying jobs. Credit: [@dieterdemeyer][]
* Added functionality for wiping out the workspace of a job.
  Credit: [@dieterdemeyer][]
* Added functionality for listing jenkins users. Credit: [@dieterdemeyer][]
* Fixed a bug where the exceptions where not thrown when using the
  `get_console_output` method.
* Fixed a bug where the jenkins_path attribute was ignored when the server_url
  input argument is given. Credit: [@woodbusy][]
* support public/private key pair authentication for Jenkins CLI.
  Credit: [@missedone][]


v0.12.1  [25-JUN-2013]
----------------------
* Fixed a bug where the SSL support was not working properly with Ruby
  1.8.7/JRuby 1.6. (Pull [#85][]) Credit: [@brettporter][]

v0.12.0  [18-JUN-2013]
----------------------
* Authentication is now optional as not all Jenkins instances have
  authentication enabled by default. Credit: [@dougforpres][]
* Ability to retrieve build details so that more than just (`lamp color`) is
  available. Credit: [@dougforpres][]
* Ability to retrieve build test-results for those builds that have them.
  Credit: [@dougforpres][]
* Option to follow any 301/302 responses. This allows POST to build to follow
  the redirect and end up with a 200 response. Credit: [@dougforpres][]
* Minor change to the POST requests handling where jenkins instances with a
  proxy returns 411 if no form data is specified. Fixed by sending an empty
  hash. Credit: [@dougforpres][]
* As of Jenkins release 1.519, the job build returns a 201 code instead of 302.
  This was resulting in an exception and the exception handling is modified to
  handle this condition.
* The jobs that are not built yet have a new color (`notbuilt`) in the recent
  version of jenkins (> 1.517) which resulted in `invalid` status. This is fixed.

v0.11.0  [09-JUN-2013]
----------------------
* A new input argument `server_url` is supported which accepts the jenkins URL
  instead of IP address and Port. Credit: [@dieterdemeyer][]
* When renaming the job, preserve the job history. Credit: [@rubytester][]
* Various exception handling improvements. Credit: [@drnic][]

v0.10.0  [24-APR-2013]
----------------------
* new function to execute jenkins CLI `cli_exec`. Credit: [@missedone][]
* Add ability to use http proxy. Credit: [@woodbusy][]
* prompt the user for credentials when using irb login script. [@woodbusy][]
* bugfix for job.console_output. Credit: [@drnic][]
* add ssl support. Credit: [@madisp][]

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
  Credit: [@Niarfe][]
* Added a timeout parameter for waiting for jenkins to become ready.
  Credit: [@Niarfe][]
* Added function to reload jenkins. Credit: [@missedone][]
* Fixed a bug where jenkins_path was missing in get_config and post_config.
  Credit: [@cylol][]
* Added capability to obtain jenkins version and other useful information
* Added new tests for various cases, and other code improvements

v0.8.1  [15-FEB-2013]
---------------------
* Fixed a bug in creating view. Issue [#42][]

v0.8.0  [14-FEB-2013]
---------------------
* Added capability to send timer trigger while creating a job
* Added rename feature for jobs
* Added support for sending skype notification in job creation and on existing
  jobs
* Added support for sending Jenkins root URL configuration. Credit: [@kevinhcross][]
* Added `delete_all!` methods for Job, View, and Node.
* `get_eta` in BuildQueue will return "N/A" if the ETA is not given by Jenkins
* Creating view accepts params Hash and more configuration through the API
* Spaces are allowed in Job, Node, and View names. Credit: [@kevinhcross][]
* Support has been added to build a job with parameters. Credit: [@tjhanley][]

v0.7.3  [05-FEB-2013]
---------------------
* Fixed [#27][] with a bug in create_view including extra character in the end of
  the name

v0.7.2  [02-FEB-2013]
---------------------
* Fixed a minor bug in `get_console_output` of Job.

v0.7.1  [30-JAN-2013]
---------------------
* Fixed a bug (Issue [#23][]) to remove the usage of "\" in Job.

v0.7.0  [27-JAN-2013]
---------------------
* Fixed a bug where the ignorecase was never used in view list
* Raise an error if the view doesnt exists while listing jobs
* Added capability to change the mode of a node
* Added support for giving node to restrict the job during creation
* Added support for notification_email option when setting up a job
* Added support for CVS provider in SCM
* Added `create_dump_slave` and `delete` methods in Node API
* Added BuildQueue class which is accessible by `[@client][].queue` method
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


<!--- The following link definition list is generated by PimpMyChangelog --->
[#23]: https://github.com/arangamani/jenkins_api_client/issues/23
[#27]: https://github.com/arangamani/jenkins_api_client/issues/27
[#42]: https://github.com/arangamani/jenkins_api_client/issues/42
[#59]: https://github.com/arangamani/jenkins_api_client/issues/59
[#85]: https://github.com/arangamani/jenkins_api_client/issues/85
[#106]: https://github.com/arangamani/jenkins_api_client/issues/106
[#112]: https://github.com/arangamani/jenkins_api_client/issues/112
[#118]: https://github.com/arangamani/jenkins_api_client/issues/118
[#119]: https://github.com/arangamani/jenkins_api_client/issues/119
[#122]: https://github.com/arangamani/jenkins_api_client/issues/122
[#126]: https://github.com/arangamani/jenkins_api_client/issues/126
[#127]: https://github.com/arangamani/jenkins_api_client/issues/127
[#128]: https://github.com/arangamani/jenkins_api_client/issues/128
[#132]: https://github.com/arangamani/jenkins_api_client/issues/132
[#134]: https://github.com/arangamani/jenkins_api_client/issues/134
[#136]: https://github.com/arangamani/jenkins_api_client/issues/136
[#140]: https://github.com/arangamani/jenkins_api_client/issues/140
[#141]: https://github.com/arangamani/jenkins_api_client/issues/141
[#145]: https://github.com/arangamani/jenkins_api_client/issues/145
[#147]: https://github.com/arangamani/jenkins_api_client/issues/147
[#148]: https://github.com/arangamani/jenkins_api_client/issues/148
[#149]: https://github.com/arangamani/jenkins_api_client/issues/149
[#151]: https://github.com/arangamani/jenkins_api_client/issues/151
[#153]: https://github.com/arangamani/jenkins_api_client/issues/153
[#156]: https://github.com/arangamani/jenkins_api_client/issues/156
[#157]: https://github.com/arangamani/jenkins_api_client/issues/157
[#158]: https://github.com/arangamani/jenkins_api_client/issues/158
[#159]: https://github.com/arangamani/jenkins_api_client/issues/159
[#161]: https://github.com/arangamani/jenkins_api_client/issues/161
[#163]: https://github.com/arangamani/jenkins_api_client/issues/163
[#165]: https://github.com/arangamani/jenkins_api_client/issues/165
[#167]: https://github.com/arangamani/jenkins_api_client/issues/167
[#168]: https://github.com/arangamani/jenkins_api_client/issues/168
[#169]: https://github.com/arangamani/jenkins_api_client/issues/169
[#172]: https://github.com/arangamani/jenkins_api_client/issues/172
[#174]: https://github.com/arangamani/jenkins_api_client/issues/174
[#176]: https://github.com/arangamani/jenkins_api_client/issues/176
[#177]: https://github.com/arangamani/jenkins_api_client/issues/177
[#179]: https://github.com/arangamani/jenkins_api_client/issues/179
[#188]: https://github.com/arangamani/jenkins_api_client/issues/188
[#191]: https://github.com/arangamani/jenkins_api_client/issues/191
[#207]: https://github.com/arangamani/jenkins_api_client/issues/207
[#213]: https://github.com/arangamani/jenkins_api_client/issues/213
[@AndrewHanes]: https://github.com/AndrewHanes
[@Loa]: https://github.com/Loa
[@Niarfe]: https://github.com/Niarfe
[@Tyrael]: https://github.com/Tyrael
[@bkon]: https://github.com/bkon
[@bobbrez]: https://github.com/bobbrez
[@brettporter]: https://github.com/brettporter
[@bsnape]: https://github.com/bsnape
[@chilicheech]: https://github.com/chilicheech
[@client]: https://github.com/client
[@cylol]: https://github.com/cylol
[@cynipe]: https://github.com/cynipe
[@cyrez]: https://github.com/cyrez
[@dieterdemeyer]: https://github.com/dieterdemeyer
[@dkerwin]: https://github.com/dkerwin
[@dougforpres]: https://github.com/dougforpres
[@drnic]: https://github.com/drnic
[@dylanmckay]: https://github.com/dylanmckay
[@gpetras]: https://github.com/gpetras
[@hubert]: https://github.com/hubert
[@jlucasps]: https://github.com/jlucasps
[@joelneubert]: https://github.com/joelneubert
[@kevinhcross]: https://github.com/kevinhcross
[@l8nite]: https://github.com/l8nite
[@lheinlen-os]: https://github.com/lheinlen-os
[@madisp]: https://github.com/madisp
[@mattrose]: https://github.com/mattrose
[@missedone]: https://github.com/missedone
[@n-rodriguez]: https://github.com/n-rodriguez
[@notruthless]: https://github.com/notruthless
[@paulgeringer]: https://github.com/paulgeringer
[@riywo]: https://github.com/riywo
[@rubytester]: https://github.com/rubytester
[@scotje]: https://github.com/scotje
[@spikegrobstein]: https://github.com/spikegrobstein
[@stjohnjohnson]: https://github.com/stjohnjohnson
[@sunaot]: https://github.com/sunaot
[@tjhanley]: https://github.com/tjhanley
[@woodbusy]: https://github.com/woodbusy