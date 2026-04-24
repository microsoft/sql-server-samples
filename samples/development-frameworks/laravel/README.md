# Myboard

[![Build Status](https://travis-ci.org/vitorfs/bootcamp.svg?branch=master)](https://travis-ci.org/vitorfs/bootcamp)

Myboard is an open source **to do board** built with [PHP][0] using the [Laravel Web Framework][1].

The project has two basic apps:

* Create todo action items
* Mark Status

## Technology Stack

- PHP 7
- Ubuntu 16.04
- Laravel 5.1
- Twitter Bootstrap 3
- Microsoft PHP SQL Server Driver
- Microsoft ODBC SQL Server Driver


## Installation Guide

### 1 Install Pre-Requisites

* **Composer**
https://getcomposer.org/download/

* **PHP**
http://php.net/releases/7_0_0.php

* **PHP Connector for SQL Server**
https://blogs.msdn.microsoft.com/sqlphp/2016/10/10/getting-started-with-php-7-sql-server-and-azure-sql-database-on-linux-ubuntu-with-apache/

* **Apache**
https://help.ubuntu.com/lts/serverguide/httpd.html

* **Mcrypt and mbstring**
http://php.net/manual/en/mcrypt.setup.php


### 2 Install dependencies
On the project root there is a requirements.pip file. Make sure you install all the required dependencies before running myboard

    cd todo
    composer install


### 3 Syncdb

Edit your database.php with your database information

    'sqlsrv' => [
			'driver'   => 'sqlsrv',
			'host'     => 'your_server',
			'database' => env('DB_DATABASE', 'your_database'),
			'username' => env('DB_USERNAME', 'sa'),
			'password' => env('DB_PASSWORD', 'your_password'),
			'prefix'   => '',
		],

Then run the database migration

    php artisan migrate
    chmod 777 -R storage

### 4 Run

    php artisan serve





[0]: http://php.net/
[1]: https://laravel.com/docs/5.1
[2]: https://github.com/meet-bhagdev/todo/wiki
