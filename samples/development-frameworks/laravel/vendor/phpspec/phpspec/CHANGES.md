2.4.1 / 2016/01/01
==================

* Correctly handle nested class definitions
* Correctly handle anonymous functions in code generation
* Fixed rerunning on Windows platform
* Fixed code generation on Windows platform
* Fixed issue with fatal errors being suppressed
* Handle underscores correctly when using PSR-4
* Fixed HTML formatter

2.4.0 / 2015/11/28
==================

* Improved docblock for beConstructedThrough()

2.4.0-rc1 / 2015/11/20
======================

* No changes from RC1

2.4.0-beta / 2015-11-13
=======================

* Handle and present fatal errors

2.4.0-alpha2 / 2015-11-03
=========================

* Fixed edge case with partial use statements

2.4.0-alpha1 / 2015-11-01
=========================

* Initial support for typehinted doubles in PHP7
* Specs can now be run by specifying a fully qualified class name
* New shouldContain matcher for strings
* Warning added when trying to typehint scalars or callable in spec
* No longer truncates strings when diffing arrays in verbose mode
* New %resource_name% placeholder for generated specs
* Fixed case error in class name that triggered strictness warnings on some platforms
* Fixed undefined index error in some versions of Windows
* Clarified in composer that ext-tokenizer is required
* Supported installation with Symfony 3.0
* Fixed error when spec and src paths are the same
* New event is fired when phpspec creates a file
* Internal refactoring of Presenter objects

2.3.0 / 2015-09-07
==================

* No changes from rc1

2.3.0-rc1 / 2015-08-28
======================

* No changes from beta3

2.3.0-beta3 / 2015-08-08
========================

* Fixed broken dependency in beta2

2.3.0-beta2 / 2015-08-08
========================

* Fixed bugs when generating methods in class with unusual whitespace

2.3.0-beta / 2015-07-04
========================

* Adds `duringInstantiation()` to more easily test constructor exceptions
* Adds `beConstructedThrough*()` and `beConstructed*()` shortcuts for named constructors
* Generated constructors are now placed at the start of the class
* Offers to make constructors private after generating a named constructor
* Shows a warning when a class is generated in a location that is not autoloadable
* Adds `%paths.config%` placeholder to allow config paths to be relative to config file
* Fixed invalid JUnit output in some non-EN locales

2.2.1 / 2015-05-30
==================

* Fix false positives in `shouldHaveKeyWithValue` matcher
* Fix fatal error in edge case when method call parameters don't match expectations

2.2.0 / 2015-04-18
==================

* No changes from rc1

2.2.0-rc1 / 2015-04-13
======================

* No changes from beta2

2.2.0-beta2 / 2015-04-03
========================

 * Better diffs when presenting unexpected method arguments
 * Better handling of methods delclared inside Traits when faking

2.2.0-beta / 2015-03-28
=======================

 * Offer to generate interfaces for missing typehinted collaborators
 * Support for TAP format output
 * Remove deprecated usage of Symfony DialogHelper
 * New array `shouldHaveKeyWithValue` matcher
 * Clearer error message when specs have incorrect namespace prefix
 * Fix suite rerunning for HHVM

Backward Compatibility
----------------------

 * The unused `ask` and `askAndValidate` methods on `Console\IO` have been removed

2.1.1 / 2015-01-09
==================

 * Smoother rendering for progress bar
 * Fixed progress bar for case where no examples are found
 * Tidier output alignment + block width
 * Removed deprecated calls to Yaml::parse
 * More accurate lower bounds for composer installation

2.1.0 / 2014-12-14
==================

 * No changes from RC3

2.1.0-RC3 / 2014-12-04
======================

 * Removed minor BC break introduced in RC2

2.1.0-RC2 / 2014-11-14
======================

  * Specify bootstrap file via configuration
  * Correct error codes while using --stop-on-failure
  * Better detection of empty specs
  * Fixed issue where non-spec files in spec folder caused errors
  * Better PSR-4 support

2.1.0-RC1 / 2014-09-14
======================

  * Allow objects to be instantiated via static factory methods
  * Automatic generation of return statements using '--fake'
  * Test suite is automatically rerun when classes or methods have been generated
  * Allow examples to mark themselves as skipped
  * PSR-4 support
  * PSR-0 locator now supports underscores correctly
  * Ability to specify a custom bootstrap file using '--bootstrap' (for autoloader registration etc)
  * Ability to have a personal .phpspec.yml in home folder
  * Progress bar grows from left to right and flickers less
  * Improved diffs for object comparison
  * Throw an exception when construction method is redefined
  * Non-zero exit code when dependencies are missing
  * Respect exit code of commands other than 'run'
  * Higher CLI verbosity levels are handled properly
  * Code Generation and Stop on Failure are configurable through phpspec.yml
  * Fixes for object instantiation changes in newer versions of PHP
  * PHP 5.6 support
  * Fixes for progress bar sometimes rounding up to 100% when not all specs passed
  * Support for non-standard Composer autoloader location
  * Improved hhvm support
  * Extensions can now register new command
  * Resource locator de-duplicates resources (supports custom locators in extensions)

2.0.1 / 2014-07-01
==================

  * Fixed the loading of the autoloader for projects using a custom composer vendor folder

2.0.0 / 2014-03-19
==================

  * Improve support to windows
  * Improve support to hhvm
  * Improve acceptance tests coverage with Behat

2.0.0-RC4 / 2014-02-21
======================

  * Revamped junit formatter
  * Fixed #269 Problem with exception masking and generation for not found class
  * HHVM is officially supported
  * Add psr0 validator
  * Remove Nyan from core
  * Added an exception if the specified config file does not exist
  * Fixed a problem with generating a constructor when it is first time added
  * Improved help
  * Fixed the suite runner in fast machines

2.0.0-RC3 / 2014-01-01
======================

  * Fixed the Prophecy constraint as the new release is 1.1
  * Refactored formatters to be defined as services

2.0.0-RC2 / 2013-12-30
======================

  * Fixed the invocation of methods expecting an argument passed by reference
  * Fixed the instantiation of the wrapped object in shouldThrow

2.0.0-RC1 / 2013-12-26
======================

  * Bump the Prophecy requirement to ``~1.0.5@dev``
  * Added a JUnit formatter
  * Added the ``--stop-on-failure`` option
  * Fixed the support of the ``--no-interaction`` option
  * Added more events to add extension points
  * Added the number of specs in the console output
  * Fixed the handling of Windows line endings in the StringEngine and in reading doc comments
  * Added extension points in the template loading
  * Added a constructor generator
  * Added a HTML formatter
  * Added a nyan cat formatter

2.0.0beta4 / 2013-05-19
=======================

  * Add collaborator constructor setter
  * Fix couple of bugs in Prophecy integration layer
  * New (old) dot formatter

2.0.0beta3 / 2013-05-01
=======================

  * Prevent loading of unexisting PHP files
  * Fix typos in the error messages

2.0.0beta2 / 2013-04-30
=======================

  * Bump required Prophecy version to 1.0.1
  * Support non-string values with ArrayContain matcher
  * Create `src` folder if does not exist
  * Fix stack trace and matchers failure printing

2.0.0beta1 / 2013-04-29
=======================

  * Initial release

