# Change Log

## [Unreleased]
### Added
### Changed
### Fixed

## [1.1.0] - 2015-01-26
### Added
- Support for non-hourly offset timezones
- Checks for valid expressions
### Changed
- Max Iterations no longer hardcoded for `getRunDate()`
- Supports DateTimeImmutable for newer PHP verions
### Fixed
- Fixed looping bug for PHP 7 when determining the last specified weekday of a month

## [1.0.3] - 2013-11-23
### Added
- Now supports expressions with any number of extra spaces, tabs, or newlines

### Changed
- Using static instead of self in `CronExpression::factory`

### Fixed
- Fixes issue [#28](https://github.com/mtdowling/cron-expression/issues/28) where PHP increments of ranges were failing due to PHP casting hyphens to 0
- Only set default timezone if the given $currentTime is not a DateTime instance ([#34](https://github.com/mtdowling/cron-expression/issues/34))