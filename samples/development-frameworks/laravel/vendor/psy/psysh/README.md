# PsySH

[![Package version](http://img.shields.io/packagist/v/psy/psysh.svg?style=flat-square)](https://packagist.org/packages/psy/psysh)
[![Build status](http://img.shields.io/travis/bobthecow/psysh/master.svg?style=flat-square)](http://travis-ci.org/bobthecow/psysh)
[![StyleCI](https://styleci.io/repos/4549925/shield)](https://styleci.io/repos/4549925)
[![Made out of awesome](http://img.shields.io/badge/made_out_of_awesome-✓-brightgreen.svg?style=flat-square)](http://psysh.org)

[![Join the chat at https://gitter.im/bobthecow/psysh](http://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg?style=flat-square)](https://gitter.im/bobthecow/psysh)


## About

PsySH is a runtime developer console, interactive debugger and [REPL](http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) for PHP. Learn more at [psysh.org](http://psysh.org/). Check out the [Interactive Debugging in PHP talk from OSCON](https://presentate.com/bobthecow/talks/php-for-pirates) on Presentate.


## Installation

Download the `psysh` phar to install:

```
wget psysh.org/psysh
chmod +x psysh
./psysh
```

It's even awesomer if you put it somewhere in your system path (like `/usr/local/bin` or `~/bin`)!

PsySH [is available via Composer](https://packagist.org/packages/psy/psysh), so you can use it in your project as well:

```
composer require psy/psysh:@stable
./vendor/bin/psysh
```

Or you can use by checking out the the repository directly:

```
git clone https://github.com/bobthecow/psysh.git
cd psysh
./bin/psysh
```


## PsySH configuration

While PsySH strives to detect the right settings automatically, you might want to configure it yourself. Just add a file to `~/.config/psysh/config.php` (or `C:\Users\{USER}\AppData\Roaming\PsySH\config.php` on Windows):

```php
<?php

return array(
    // In PHP 5.4+, PsySH will default to your `cli.pager` ini setting. If this
    // is not set, it falls back to `less`. It is recommended that you set up
    // `cli.pager` in your `php.ini` with your preferred output pager.
    //
    // If you are running PHP 5.3, or if you want to use a different pager only
    // for Psy shell sessions, you can override it here.
    'pager' => 'more',

    // Sets the maximum number of entries the history can contain.
    // If set to zero, the history size is unlimited.
    'historySize' => 0,

    // If set to true, the history will not keep duplicate entries.
    // Newest entries override oldest.
    // This is the equivalent of the HISTCONTROL=erasedups setting in bash.
    'eraseDuplicates' => false,

    // By default, PsySH will use a 'forking' execution loop if pcntl is
    // installed. This is by far the best way to use it, but you can override
    // the default by explicitly enabling or disabling this functionality here.
    'usePcntl' => false,

    // PsySH uses readline if you have it installed, because interactive input
    // is pretty awful without it. But you can explicitly disable it if you hate
    // yourself or something.
    'useReadline' => false,

    // PsySH automatically inserts semicolons at the end of input if a statement
    // is missing one. To disable this, set `requireSemicolons` to true.
    'requireSemicolons' => true,

    // While PsySH respects the current `error_reporting` level, and doesn't throw
    // exceptions for all errors, it does log all errors regardless of level. Set
    // `errorLoggingLevel` to 0 to prevent logging non-thrown errors. Set it to any
    // valid `error_reporting` value to log only errors which match that level.
    'errorLoggingLevel' => E_ALL & ~E_NOTICE,

    // "Default includes" will be included once at the beginning of every PsySH
    // session. This is a good place to add autoloaders for your favorite
    // libraries.
    'defaultIncludes' => array(
        __DIR__ . '/include/bootstrap.php',
    ),

    // While PsySH ships with a bunch of great commands, it's possible to add
    // your own for even more awesome. Any Psy command added here will be
    // available in your Psy shell sessions.
    'commands' => array(
        // The `parse` command is a command used in the development of PsySH.
        // Given a string of PHP code, it pretty-prints the
        // [PHP Parser](https://github.com/nikic/PHP-Parser) parse tree. It
        // prolly won't be super useful for most of you, but it's there if you
        // want to play :)
        new \Psy\Command\ParseCommand,
    ),

    // PsySH uses symfony/var-dumper's casters for presenting scalars, resources,
    // arrays and objects. You can enable additional casters, or write your own!
    // See http://symfony.com/doc/current/components/var_dumper/advanced.html#casters
    'casters' => array(
        'MyFooClass' => 'MyFooClassCaster::castMyFooObject',
    ),

    // You can disable tab completion if you want to. Not sure why you'd want to.
    'tabCompletion' => false,

    // You can write your own tab completion matchers, too! Here are some that enable
    // tab completion for MongoDB database and collection names:
    'tabCompletionMatchers' => array(
        new \Psy\TabCompletion\Matcher\MongoClientMatcher,
        new \Psy\TabCompletion\Matcher\MongoDatabaseMatcher,
    ),

    // If multiple versions of the same configuration or data file exist, PsySH will
    // use the file with highest precedence, and will silently ignore all others. With
    // this enabled, a warning will be emitted (but not an exception thrown) if multiple
    // configuration or data files are found.
    //
    // This will default to true in a future release, but is false for now.
    'warnOnMultipleConfigs' => true,
);
```


## Downloading the manual

The PsySH `doc` command is great for documenting source code, but you'll need a little something extra for PHP core documentation. Download one of the following PHP Manual files and drop it in `~/.local/share/psysh/` (or `C:\Users\{USER}\AppData\Roaming\PsySH\` on Windows):

 * **[English](http://psysh.org/manual/en/php_manual.sqlite)**
 * [Brazilian Portuguese](http://psysh.org/manual/pt_BR/php_manual.sqlite)
 * [Chinese (Simplified)](http://psysh.org/manual/zh/php_manual.sqlite)
 * [French](http://psysh.org/manual/fr/php_manual.sqlite)
 * [German](http://psysh.org/manual/de/php_manual.sqlite)
 * [Italian](http://psysh.org/manual/it/php_manual.sqlite)
 * [Japanese](http://psysh.org/manual/ja/php_manual.sqlite)
 * [Polish](http://psysh.org/manual/pl/php_manual.sqlite)
 * [Romanian](http://psysh.org/manual/ro/php_manual.sqlite)
 * [Russian](http://psysh.org/manual/ru/php_manual.sqlite)
 * [Persian](http://psysh.org/manual/fa/php_manual.sqlite)
 * [Spanish](http://psysh.org/manual/es/php_manual.sqlite)
 * [Turkish](http://psysh.org/manual/tr/php_manual.sqlite)



## As Seen On…

 * Cake: [`cake console`](http://book.cakephp.org/3.0/en/console-and-shells/repl.html)
 * Drupal: [`drush php`](http://drushcommands.com/drush-7x/core/core-cli), [drush-psysh](https://github.com/grota/drush-psysh)
 * eZ Publish: [`ezsh`](https://github.com/lolautruche/ezsh)
 * Laravel: [`artisan tinker`](https://github.com/laravel/framework/blob/5.0/src/Illuminate/Foundation/Console/TinkerCommand.php)
 * Lumen: [`artisan tinker`](https://github.com/vluzrmos/lumen-tinker)
 * Magento: [`magerun console`](https://github.com/netz98/n98-magerun/blob/develop/src/N98/Magento/Command/Developer/ConsoleCommand.php)
 * Pantheon CLI: [`terminus cli console`](https://github.com/pantheon-systems/cli)
 * Symfony: [sf1-psysh-bootstrap](https://github.com/varas/sf1-psysh-bootstrap)
 * Symfony2: [`psymf`](https://github.com/navitronic/psymf), [sf2-psysh-bootstrap](https://github.com/varas/sf2-psysh-bootstrap), [symfony-repl](https://github.com/luxifer/symfony-repl), [PsyshBundle](https://github.com/theofidry/PsyshBundle)
 * WordPress: [`wp-cli shell`](https://github.com/wp-cli/wp-cli/blob/master/php/commands/shell.php)
 * Zend Framework 2: [PsyshModule](https://zfmodules.com/gianarb/zf2-psysh-module)
