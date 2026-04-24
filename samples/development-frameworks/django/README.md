# Bootcamp

[![Build Status](https://travis-ci.org/vitorfs/bootcamp.svg?branch=master)](https://travis-ci.org/vitorfs/bootcamp)

Bootcamp is an open source **enterprise social network** built with [Python][0] using the [Django Web Framework][1].

The project has three basic apps:

* Feed (A Twitter-like microblog)
* Articles (A collaborative blog)
* Question & Answers (A Stack Overflow-like platform)

## Feed App

The Feed app has infinite scrolling, activity notifications, live updates for likes and comments, and comment tracking.


## Articles App

The Articles app is a basic blog, with articles pagination, tag filtering and draft management.


## Question & Answers App

The Q&A app works just like Stack Overflow. You can mark a question as favorite, vote up or vote down answers, accept an answer and so on.


## Technology Stack

- Python 2.7
- Django 1.9.4
- Twitter Bootstrap 3
- jQuery 2


## Installation

### 1 Install Python 2.7 and Django Framework 1.9

**Python 2.7.x**
https://www.python.org/downloads/



### 2 Install dependencies
On the project root there is a requirements.pip file. Make sure you install all the required dependencies before running Bootcamp

    pip install -U -r requirements.txt

**Note:** If you are having problems with Pillow installation please take a look on a detailed installation guide at: http://pillow.readthedocs.org/en/latest/installation.html


### 3 Syncdb

Edit your settings.py file with your database information

    DATABASES = {
        'default': {
             'ENGINE': 'sql_server.pyodbc',
             'NAME': 'django',
             'USER': 'yourusername',
             'PASSWORD': 'yourpassword',
             'HOST': 'yourserver',
             'PORT': '1433',

             'OPTIONS': {
                  'driver': 'ODBC Driver 13 for SQL Server',
             },
         },
    }

Then run the database migration

    python manage.py migrate

### 4 Run

    python manage.py runserver


## Demo

Try Bootcamp now at [http://trybootcamp.vitorfs.com][2].

[0]: https://www.python.org/
[1]: https://www.djangoproject.com/
[2]: http://trybootcamp.vitorfs.com/
