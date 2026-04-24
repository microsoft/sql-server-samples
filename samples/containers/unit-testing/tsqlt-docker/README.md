<!-- Always leave the MS logo -->
![](https://github.com/microsoft/sql-server-samples/blob/master/media/solutions-microsoft-logo-small.png)

# SQL Server unit testing with tSQLt, Docker, and GitHub Actions!

This sample describes how to automate the testing for one or more SQL Server objects using tSQLt, Docker, and GitHub Actions!

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Case history](#case-history)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2016 (or higher)
- **Key features:** Run SQL Server in Docker containers
- **Workload:** Unit tests executed on [AdventureWorks](https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks)
- **Programming Language:** T-SQL, YAML
- **Authors:** [Sergio Govoni](https://www.linkedin.com/in/sgovoni/) | [Microsoft MVP Profile](https://mvp.microsoft.com/it-it/PublicProfile/4029181?fullName=Sergio%20Govoni) | [Blog](https://segovoni.medium.com/) | [GitHub](https://github.com/segovoni) | [Twitter](https://twitter.com/segovoni)

<a name=before-you-begin></a>

## Before you begin

To run this example, the following basic concepts are required.

[tSQLt](https://tsqlt.org/) is a unit testing framework for SQL Server. It provides the APIs to create and execute test cases, as well as integrates them with continuous integration servers. The power of the tSQLt framework has been described in my article [The tSQLt framework and the execution of a test](https://segovoni.medium.com/unit-testing-the-tsqlt-framework-and-the-execution-of-a-test-e4d135c3e343).

[Docker](https://www.docker.com/) is one of the most popular systems for running applications in isolable, minimal and easily deployable environments called containers. Since SQL Server 2017, the SQL Server Engine can run in a Docker container, a typical usage of running SQL Server in a Docker container concerns the automation of software tests.

[GitHub Actions](https://github.com/features/actions/) is a continuous integration and continuous delivery (CI/CD) platform that allows you to automate your build, test, and deployment pipeline. You can create workflows that build and test every pull request to your repository, or deploy merged pull requests to production. GitHub provides Linux, Windows, and macOS virtual machines to run your workflows, or you can host your own self-hosted runners in your own data center or cloud infrastructure such as Microsoft Azure.

**Software prerequisites:**

1. A GitHub account. If you don't already have a GitHub account, you can get one for free [here](https://github.com/signup)!

<a name=case-history></a>

## Case history

The AdventureWorks database contains the `Production.Product` table that stores products managed and sold by the fake company Adventure Works LTD.

The trigger we have wrote is to prevent the insertion of new products with values less than 10 as a “safety stock”. The Company wishes to always have a warehouse stock of no less than 10 units for each product. The safety stock level is a very important value for the automatic procedures: it allows to re-order materials. The creation of new purchase orders and production orders are based on the safety stock level. To make our trigger simple, it will only respond to the `OnInsert` event, for `INSERT` commands.

<a name=run-this-sample></a>

## Run this sample

<!-- Step by step instructions -->

1. [Sign in](https://github.com/login) to GitHub. If you don't already have an account, [sign up for a new GitHub account](https://docs.github.com/get-started/signing-up-for-github/signing-up-for-a-new-github-account)
2. Create your sample repository on GitHub, if you've never done it, you can find the guide [here](https://docs.github.com/get-started/quickstart/create-a-repo)
3. Create a `.github/workflows` directory in your GitHub repository if this directory does not already exist
4. Copy the [automated-tests.yml](https://github.com/microsoft/sql-server-samples/tree/master/samples/containers/unit-testing/tsqlt-docker/.github/workflows) inside the directory `.github/workflows` you created in the previous step in your repository. The `automated-tests.yml` describes the process that will execute one or more jobs
5. Create the `source` and `unit-test` directories in the root of your sample repository
6. Copy all the files located in the [source](https://github.com/microsoft/sql-server-samples/tree/master/samples/containers/unit-testing/tsqlt-docker/source) and [unit-test](https://github.com/microsoft/sql-server-samples/tree/master/samples/containers/unit-testing/tsqlt-docker/unit-test) directories to their respective directories in your repository
7. View and run the workflow as described [here](https://docs.github.com/actions/quickstart)
8. Have fun with the solution details outlined below

**The challenge**

The implementation of the trigger and related unit tests has been done, all files are ready in your repository!

The challenge is to automate the execution of the tests at each commit on the main branch of the repository. GitHub Actions is our CI/CD platform, it supports the use of Docker containers and it is intimately integrated into GitHub, the source control that manages our source code.

**Understand and manage your first workflow**

Workflows are defined with a YAML file stored in the same repository which holds the source code. The workflows will be triggered when an event occurs in the repository. Anyway, a workflow can also be activated manually or according to a defined schedule.

A sample YAML file that implements the test automation workflow is already in your sample repository, the fundamental steps of the process are:

1. Definition of activation events
2. Creating a Docker container from a SQL Server image on Linux
3. AdventureWorks database recovery
4. Installation of the tSQLt framework
5. Creating the database objects to be tested (SUT)
6. Creation and execution unit tests

**1. Definition of activation events**

The definition of the activation events is typically done at the beginning of the YAML script with a code snippet similar to the one shown below. The workflow is activated when push or pull request events occur on the `master` branch. The `workflow_dispatch` specification allows you to run the workflow manually from the actions tab.

```
# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "master" branch
  push:
    branches: [ "master" ]
  pull_request:
    branches: [ "master" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:
```

**2. Creating a Docker container from a SQL Server image on Linux**

Creating a Docker container from a SQL Server image on Linux can be done by requesting the `sqlserver service` accompanied by the path to the Docker image you want to use.

The official images provided by Microsoft for SQL Server on Linux are available [here](https://hub.docker.com/_/microsoft-mssql-server).

We will not use an official image downloaded from the Microsoft registry. We will use a Docker image of SQL Server with the AdventureWorks database installed, this image is published by [chriseaton](https://hub.docker.com/u/chriseaton), you can find it at this [link](https://hub.docker.com/r/chriseaton/adventureworks).

The following YAML code snippet sets up the SQL Server service.

```
jobs:

  windows-auth-tsqlt:

    name: Installting tSQLt framework with SQL Auth and running unit tests

    # The type of runner that the job will run on
    runs-on: ubuntu-latest
    
    services:
      sqlserver:
        image: chriseaton/adventureworks:latest
        ports:
          - 1433:1433
        env:
          ACCEPT_EULA: Y
          SA_PASSWORD: 3uuiCaKxfbForrK
```

In order to reference the newly created Docker container it is important to save its identifier in an environment variable.

The following snippet of YAML code sets the `ENV_CONTAINER_ID` variable with the ID of the container created.

```
- name: Set environment variable ENV_CONTAINER_ID
  run: echo "ENV_CONTAINER_ID=$(docker ps --all --filter status=running --no-trunc --format "{{.ID}}")" >> $GITHUB_ENV
```

**3. AdventureWorks database recovery**

The AdventureWorks database recovery can be performed using the following docker exec command.

```
- name: Restore AdventureWorks
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -Q "RESTORE DATABASE [AdventureWorks2017] FROM DISK = '/adventureworks.bak' WITH MOVE 'AdventureWorks2017' TO '/var/opt/mssql/data/AdventureWorks.mdf', MOVE 'AdventureWorks2017_log' TO '/var/opt/mssql/data/AdventureWorks_log.ldf'"
```

**4. Installation of the tSQLt framework**

The installation of the latest version of tSQLt framework in the AdventureWorks database is done using the GitHub Actions tSQLt Installer published by [lowlydba](https://github.com/lowlydba), you can find more details [here](https://github.com/lowlydba/tsqlt-installer) and on the [GitHub Actions marketplace](https://github.com/marketplace/actions/tsqlt-installer).

The snippet of YAML code used for the installation of the tSQLt framework in the AdventureWorks database is the following.

```
steps:
  - uses: actions/checkout@v3.5.2
  - name: Install tSQLt with SQL auth on AdventureWorks2017
    uses: lowlydba/tsqlt-installer@v1
    with:
      sql-instance: localhost
      database: AdventureWorks2017
      version: latest
      user: sa
      password: 3uuiCaKxfbForrK
```

**5. Creating the database objects to be tested (SUT)**

The test environment is ready, we have a SQL Server instance on Linux inside a Docker container; the AdventureWorks database has been restored and it is ready for use.

Let's go ahead with the creation of the trigger and the stored procedure (that manages errors), they represent our [System Under Test (SUT)](https://en.wikipedia.org/wiki/System_under_test).

The TR_Product_SafetyStockLevel trigger creation script and the usp_Raiserror_SafetyStockLevel stored procedure creation script are saved in the source directory of this sample.

Triggers and stored procedures are created in the AdventureWorks database attached to the SQL Server instance, the YAML code snippet that performs this operation is the following.

```
- name: Create sp usp_Raiserror_SafetyStockLevel
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./source/usp-raiserror-safetystocklevel.sql

- name: Create system under test (SUT) TR_Product_SafetyStockLevel
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./source/tr-product-safetystocklevel.sql
```

**6. Creation and execution of test units**

The last phase of this workflow is represented by the creation and execution of the unit tests.

The test class and the unit tests creation scripts are contained in the unit-test subfolder of this sample.

Let's go ahead with the creation of the test class dedicated to the TR_Product_SafetyStockLevel trigger, we called it UnitTestTRProductSafetyStockLevel.

The following docker exec command, that uses sqlcmd, executes the TSQL commands contained in the test-class-trproductsafetystocklevel.sql script.

```
- name: Create test class UnitTestTRProductSafetyStockLevel
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./unit-test/test-class-trproductsafetystocklevel.sql
```

Let's go ahead with the creation and execution of the unit tests. Each .sql file of the test case family contains the TSQL commands for creating and running the related unit test. Each store procedure tests one and only one test case.

The following snippet of YAML code creates and runs the test units.

```
- name: Create and run test case try to insert one wrong row
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./unit-test/test-case-try-to-insert-one-wrong-row.sql

- name: Create and run test case try to insert one right row
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./unit-test/test-case-try-to-insert-one-right-row.sql

- name: Create and run test case try to insert multiple rows
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./unit-test/test-case-try-to-insert-multiple-rows.sql

- name: Create and run test case try to insert multiple rows ordered
  run: docker exec -i $ENV_CONTAINER_ID /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "3uuiCaKxfbForrK" -d AdventureWorks2017 -b < ./unit-test/test-case-try-to-insert-multiple-rows-ordered.sql
```

The YAML script for our workflow is complete, you can find it here.

<a name=sample-details></a>

## Sample details

Unit tests developed for a SQL Server solution are not just meant to verify that requirements have been met once, prior to release; the real game changer is represented by the possibility of repeating the checks during the development of new code and during the bug fixing process.

The repeatability of the tests provides the ability to automate them, an essential condition for integrating automatic tests within a Continuous Integration platform. In this article we described how to automate the testing of SQL Server objects using tSQLt, Docker and GitHub Actions!

<a name=disclaimers></a>

## Disclaimers

The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade unit testing or CI/CD system. This is beyond the scope of this quick start sample.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For more information, see these articles:

- [Unit testing: What it is and why it is important for T-SQL code!](https://medium.com/@segovoni/unit-testing-what-it-is-and-why-it-is-important-for-t-sql-code-7e9df7ca8bfe)
- [Unit testing: The tSQLt framework and the execution of a test!](https://segovoni.medium.com/unit-testing-the-tsqlt-framework-and-the-execution-of-a-test-e4d135c3e343)
- [Unit testing: How to write your first unit test for T-SQL code](https://segovoni.medium.com/unit-testing-how-to-write-your-first-unit-test-for-t-sql-code-3bc1533acbbc)
