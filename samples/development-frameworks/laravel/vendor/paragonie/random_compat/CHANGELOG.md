### Version 1.2.0 - 2015-02-05

* Whitespace and other cosmetic changes
* Added a changelog.
* We now ship with a command line utility to build a PHP Archive from the
  command line.

  Every time we publish a new release, we will also upload a .phar
  to Github. Our public key is signed by our GPG key.

### Version 1.1.6 - 2015-01-29

* Eliminate `open_basedir` warnings by detecting this configuration setting.
  (Thanks [@oucil](https://github.com/oucil) for reporting this.)
* Added install instructions to the README.
* Documentation cleanup (there is, in fact, no `MCRYPT_CREATE_IV` constant, I
  meant to write `MCRYPT_DEV_URANDOM`)

### Version 1.1.5 - 2016-01-06

Prevent fatal errors on platforms with older versions of libsodium.

### Version 1.1.4 - 2015-12-10

Thanks [@narfbg](https://github.com/narfbg) for [critiquing the previous patch](https://github.com/paragonie/random_compat/issues/79#issuecomment-163590589)
and suggesting a fix.

### Version 1.1.3 - 2015-12-09

The test for COM in disabled_classes is now case-insensitive.

### Version 1.1.2 - 2015-12-09

Don't instantiate COM if it's a disabled class. Removes the E_WARNING on Windows.

### Version 1.1.1 - 2015-11-30

Fix a performance issue with `/dev/urandom` buffering.

### Version 1.1.0 - 2015-11-09

Fix performance issues with ancient versions of PHP on Windows, but dropped
support for PHP < 5.4.1 without mcrypt on Windows 7+ in the process. Since this
 is a BC break, semver dictates a minor version bump.

### Version 1.0.10 - 2015-10-23

* Avoid a performance killer with OpenSSL on Windows PHP 5.3.0 - 5.3.3 that was
  affecting [WordPress users](https://core.trac.wordpress.org/ticket/34409).
* Use `$var = null` instead of `unset($var)` to avoid triggering the garbage
  collector and slowing things down.

### Version 1.0.9 - 2015-10-20

There is an outstanding issue `mcrypt_create_iv()` and PHP 7's `random_bytes()`
on Windows reported by [@nicolas-grekas](https://github.com/nicolas-grekas) caused by `proc_open()` and environment
variable handling (discovered by Appveyor when developing Symfony).

Since the break is consistent, it's not our responsibility to fix it, but we
should fail the same way PHP 7 will (i.e. throw an `Exception` rather than raise
an error and then throw an `Exception`).

### Version 1.0.8 - 2015-10-18

* Fix usability issues with Windows (`new COM('CAPICOM.Utilities.1')` is not
  always available).
* You can now test all the possible drivers by running `phpunit.sh each` in the
  `tests` directory.

### Version 1.0.7 - 2015-10-16

Several large integer handling bugfixes were contributed by [@oittaa](https://github.com/oittaa).

### Version 1.0.6 - 2015-10-15

Don't let the version number fool you, this was a pretty significant change.

1. Added support for ext-libsodium, if it exists on the system. This is morally
   equivalent to adding `getrandom(2)` support without having to expose the
   syscall interface in PHP-land.
2. Relaxed open_basedir restrictions. In previous versions, if open_basedir was
   set, PHP wouldn't even try to read from `/dev/urandom`. Now it will still do
   so if you can.
3. Fixed integer casting inconsistencies between random_compat and PHP 7.
4. Handle edge cases where an integer overflow turns one of the parameters into
   a float.

One change that we discussed was making `random_bytes()` and `random_int()`
strict typed; meaning you could *only* pass integers to either function. While
most veteran programmers are probably only doing this already (we strongly
encourage it), it wouldn't be consistent with how these functions behave in PHP
7. Please use these functions responsibly.

We've had even more of the PHP community involved in this release; the
contributors list has been updated. If I forgot anybody, I promise you it's not
because your contributions (either code or ideas) aren't valued, it's because
I'm a bit overloaded with information at the moment. Please let me know
immediately and I will correct my oversight.

Thanks everyone for helping make random_compat better.

### Version 1.0.5 - 2015-10-08

Got rid of the methods in the `Throwable` interface, which was causing problems
on PHP 5.2. While we would normally not care about 5.2 (since [5.4 and earlier are EOL'd](https://secure.php.net/supported-versions.php)),
we do want to encourage widespread adoption (e.g. [Wordpress](https://core.trac.wordpress.org/ticket/28633)).

### Version 1.0.4 - 2015-10-02

Removed redundant `if()` checks, since `lib/random.php` is the entrypoint people
should use.

### Version 1.0.3 - 2015-10-02

This release contains bug fixes contributed by the community.

* Avoid a PHP Notice when PHP is running without the mbstring extension
* Use a compatible version of PHPUnit for testing on older versions of PHP

Although none of these bugs were outright security-affecting, updating ASAP is
still strongly encouraged.

### Version 1.0.2 - 2015-09-23

Less strict input validation on `random_int()` parameters. PHP 7's `random_int()`
accepts strings and floats that look like numbers, so we should too.

Thanks [@dd32](https://github.com/@dd32) for correcting this oversight.

### Version 1.0.1 - 2015-09-10

Instead of throwing an Exception immediately on insecure platforms, only do so
when `random_bytes()` is invoked.

### Version 1.0.0 - 2015-09-07

Our API is now stable and forward-compatible with the CSPRNG features in PHP 7
(as of 7.0.0 RC3).

A lot of great people have contributed their time and expertise to make this
compatibility library possible. That this library has reached a stable release
is more a reflection on the community than it is on PIE.

We are confident that random_compat will serve as the simplest and most secure
CSPRNG interface available for PHP5 projects.

### Version 0.9.7 (pre-release) - 2015-09-01

An attempt to achieve compatibility with Error/TypeError in the RFC.

This should be identical to 1.0.0 sans any last-minute changes or performance enhancements.

### Version 0.9.6 (pre-release) - 2015-08-06

* Split the implementations into their own file (for ease of auditing)
* Corrected the file type check after `/dev/urandom` has been opened (thanks
  [@narfbg](https://github.com/narfbg) and [@jedisct1](https://github.com/jedisct1))

### Version 0.9.5 (pre-release) - 2015-07-31

* Validate that `/dev/urandom` is a character device
  * Reported by [@lokdnet](https://twitter.com/lokdnet)
  * Investigated by [@narfbg](https://github.com/narfbg) and [frymaster](http://stackoverflow.com/users/1226810/frymaster) on [StackOverflow](http://stackoverflow.com/q/31631066/2224584)
* Remove support for `/dev/arandom` which is an old OpenBSD feature, thanks [@jedisct1](https://github.com/jedisct1)
* Prevent race conditions on the `filetype()` check, thanks [@jedisct1](https://github.com/jedisct1)
* Buffer file reads to 8 bytes (performance optimization; PHP defaults to 8192 bytes)

### Version 0.9.4 (pre-release) - 2015-07-27

* Add logic to verify that `/dev/arandom` and `/dev/urandom` are actually devices.
* Some clean-up in the comments

### Version 0.9.3 (pre-release) - 2015-07-22

Unless the Exceptions change to PHP 7 fails, this should be the last pre-release
version. If need be, we'll make one more pre-release version with compatible
behavior.

Changes since 0.9.2:

* Prioritize `/dev/arandom` and `/dev/urandom` over mcrypt.
[@oittaa](https://github.com/oittaa) removed the -1 and +1 juggling on `$range` calculations for `random_int()`
* Whitespace and comment clean-up, plus better variable names
* Actually put a description in the composer.json file...

### Version 0.9.2 (pre-release) - 2015-07-16

* Consolidated `$range > PHP_INT_MAX` logic with `$range <= PHP_INT_MAX` (thanks
  [@oittaa](https://github.com/oittaa) and [@CodesInChaos](https://github.com/CodesInChaos))
* `tests/phpunit.sh` now also runs the tests with `mbstring.func_overload` and
  `open_basedir`
* Style consistency, whitespace cleanup, more meaningful variable names

### Version 0.9.1 (pre-release) - 2015-07-09

* Return random values on integer ranges > `PHP_INT_MAX` (thanks [@CodesInChaos](https://github.com/CodesInChaos))
* Determined CSPRNG preference:
    1. `mcrypt_create_iv()` with `MCRYPT_DEV_URANDOM`
    2. `/dev/arandom`
    3. `/dev/urandom`
    4. `openssl_random_pseudo_bytes()`
* Optimized backend selection (thanks [@lt](https://github.com/lt))
* Fix #3 (thanks [@scottchiefbaker](https://github.com/scottchiefbaker))

### Version 0.9.0 (pre-release) - 2015-07-07

This should be a sane polyfill for PHP 7's `random_bytes()` and `random_int()`.
We hesitate to call it production ready until it has received sufficient third
party review.