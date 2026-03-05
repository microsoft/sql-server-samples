# Release notes for SQL Assessment API

This article provides details about updates, improvements, and bug fixes for the current and previous versions of SQL Assessment API. 

To start working with the API, install the SQL Assessment Extention to Azure Data Studio or utilize either the SqlServer module or SMO.

Installing SQL Assessment Extension: [SQL Server Assessment Extension for Azure Data Studio (Public Preview)](https://techcommunity.microsoft.com/t5/sql-server/released-sql-server-assessment-extension-for-azure-data-studio/ba-p/1470603)

Download: [SQL Assessment NuGet package](https://www.nuget.org/packages/Microsoft.SqlServer.Assessment)

Download: [Download SqlServer module](https://www.powershellgallery.com/packages/SqlServer)

Download: [SMO NuGet Package](https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects)

You can use GitHub issues to provide feedback to the product team.

## March 2021 - 1.0.305

Version: SqlServer PowerShell module 21.1.18245, SqlManagementObjects (SMO) package wasn't updated

### Bug fixes and improvements

- Fixed an issue that may cause the 'ReplErrors24H' check to fail on case-sensitive SQL Server instances with Distributor databases

## March 2021 - 1.0.304

Version: SqlServer PowerShell module wasn't updated, SqlManagementObjects (SMO) package wasn't updated

### What's new

- Added the 'MachineType' property to Target that is used for making rules specific to SQL Server on Azure Virtual Machine
- Added the ability to pass data among multiple probes and invoke probes one by one
- Added rules:
  - [SQL Server on Azure VM] VM size is not memory-optimized - checks the virtual machine size and recommends to use memory-optimized VM series for the best performance of SQL Server workloads
  - 'SQL Server Agent' service uses non-recommended account
  - 'SQL Server Agent' service uses not supported account
  - 'SQL Server Agent' and 'SQL Server Database Engine' use same account
  - 'SQL Server Agent' service is stopped
  - 'SQL Server Browser' and 'SQL Server Database Engine' use same account
  - 'SQL Server Browser' service is stopped
  - 'Integration Services' and 'SQL Server Database Engine' use same account
  - 'Integration Services' service is stopped
  - 'Full-text search' service uses non-recommended account
  - 'Full-text search' and 'SQL Server Database Engine' use same account
  - 'Full-text search' service is stopped
  - 'Analysis Services' and 'SQL Server Database Engine' use same account
  - 'Analysis Services' service is stopped
  - 'Reporting Services' and 'SQL Server Database Engine' use same account
  - 'Reporting Services' service is stopped
  - 'SQL Server Database Engine' service uses non-recommended account
  - 'SQL Server Database Engine' service uses not supported account

### Bug fixes and improvements

- Updated the 'LatestCU' rule with the latest CU versions 
- Updated the 'ReplErrors24H' rule to collect information for all 'Publisher' databases 
- Fixed an issue with local variables used for displaying extended details in messages 
- Fixed an issue with the wrong Linux target type for the 'PriorityBoostOn' rule

## December 2020 - 1.0.302

Version: SqlServer PowerShell module wasn't updated, SqlManagementObjects (SMO) package wasn't updated

### What's new

- Added rules:
  - 'Max server memory' and 'Max server memory exceeds system memory' that check if the 'max server memory' setting falls within the recommended range
  - 'Error log file is too big' that checks if there are any big error log files
- 'Disk fragmentation analysis' that checks if a disk needs to be defragmented
- New features for custom configuration files:
  - Added new 'defaultValue' data transformation functions
  - Added new functions:
    - 'max' and 'min' functions that return maximum and minimum values of their arguments
    - 'ieq' and 'ine' case-insensitive functions that check if the given arguments are equal
    - 'iin' case-insensitive function that checks if a value is present in the given set
    - 'interval' function that finds an interval into which the given argument falls and returns an associated value.
    - 'startswith' and 'endswith' functions that check if one string starts or ends with another one, and their case-insensitive variants 'istartswith' and 'iendswith'
    - 'indexof' function that finds the first occurrence of a substring, and its case-insensitive variant 'iindexof'
  - Added local variables to assessment rules which can be used to show more details in messages
  - Added WMI method call support to custom WMI probes

### Bug fixes and improvements

- Removed non-informative errors thrown from recursive assessment of SQL Server Registered Groups
- Improved query performance for probes used in the 'Replication errors in the last 24 hours' rule
- Updated MaxDOP related rules to follow the best practice recommendations
- Fixed an issue that may occur when the 'automatic_soft_NUMA_disabled' configuration setting value was not returned by some SQL Server instances
- Fixed an issue that may occur when the 'sql_memory_model' value was not returned by some SQL Server instances

## July 2020 - 1.0.265

Version: SqlServer module 21.1.18226, SqlManagementObjects (SMO) package wasn't updated

### What's new

- Added new types of probes in addition to SQL and EXTERNAL: CMDSHELL, WMI, REGISTRY, POWERSHELL
- Enabling/disabling database checks for particular SQL Server instances (by instance name)
- Added 40 rules, including  
  - Ad Hoc Distributed Queries are enabled
  - Affinity Mask and Affinity I/O Mask overlapping
  - Auto Soft NUMA should be enabled
  - Blocking chains
  - Blocked Process Threshold is set to recommended value
  - Option 'cross db ownership chaining' should be disabled
  - Default trace enabled
  - Disk Partition alignment
  - Full-text search option 'load_os_resources' set to default
  - Full-text search option 'verify_signature' set to default
  - HP Logical Processor issue
  - Option 'index create memory' value should be greater 'min memory per query'
  - Lightweight pooling option disabled
  - Option 'locks' should be set to default
  - Option 'min memory per query' set to default
  - Option 'network packet size' set to default
  - NTFS block size in volumes that hold database files <> 64KB
  - Option 'Ole Automation Procedures' set to default
  - Page file is not automatically managed
  - Insufficient page file free space
  - Page file configured
  - Memory paged out
  - Power plan is High Performance
  - Option 'priority boost' set to default
  - Option 'query wait' set to default
  - Option 'recovery interval' set to default
  - Remote admin connections enabled on cluster (DAC)
  - Option 'remote query timeout' set to default
  - Option 'scan for startup procs' disabled on replication servers
  - Worker thread exhaustion on CPU-bound system
  - Possible worker thread exhaustion on a not-CPU-bound system
  - Option 'cost threshold for parallelism' set to default
  - Option 'max worker threads' set to recommended value on x64 system
  - Option 'max worker threads' set to recommended value on x86 system
  - Option 'xp_cmdshell' is disabled

## March 2020 - 1.0.246

Version: SqlServer module 21.1.18221, SqlManagementObjects (SMO) package 160.2004021.0

### What's new

- Platform, Name, and engineEdition fields can now contain usual comma-separated lists ("platform": \["Windows", "Linux"\]), not only regular expressions ("platform": "/Windows|Linux/")
- Added rule "Database files have a growth ratio set in percentage"
- Added rule "STRelate and STAsBinary functions unexpected results due to TF 6533 enabled"
- Added rule "Database Integrity Checks"
- Added rule "Direct Catalog Updates"
- Added rule "Data Purity Check"
- Added rule "MaxDOP should be less or equal number of CPUs"
- Added rule "MaxDOP should equal number of CPUs for single NUMA node"
- Added rule "MaxDOP should be less 8 for single NUMA node"
- Added rule "MaxDOP should be according to processor count ratio"
- Added rule "Pending disk I/O requests"
- Added rule "Index Fragmentation"
- Added rule "Untrusted Constraints"
- Added rule "Statistics need to be updated"

### Bug fixes

- Wrong help link in XTPHashAvgChainBuckets rule
- Occasional error "There is already an open DataReader associated with this Command which must be closed first" on PowerShell 7

## December 2019 - 1.0.220

Version: SqlServer module 21.1.18206, SqlManagementObjects (SMO) package wasn't updated

### What's new

- Added .DLL with types to get rid of recompilation of CLR probes assemblies every time when new version of solution is released
- Updated Deprecated Features rules and Index rules to not run them against system DBs
- Updated rules High CPU Usage: kept only one, added overridable threshold
- Updated some rules to not run them against SQL Server 2008
- Added timestamp property to rule object

### Bug fixes

- Error "Missing data item 'FilterDefinition'" when overriding Exclusion DB List
- Probe of rule Missed Indexes returns nothing
- FullBackup rule has threshold in days but gets backup age in hours
- When database can't be accessed and it's disabled for assessment, it throws access errors when performing assessment

## GA - November 2019 - 1.0.216

Version: SqlServer module 21.1.18206, SqlManagementObjects (SMO) package 150.208.0

### What's new

- Added 50 assessment rules
- Added base math expressions and comparisons to rules conditions
- Added support for RegisteredServer object
- Updated way how rules are stored in the JSON format and also updated the mechanism of applying overrides/customizations
- Updated rules to support SQL on Linux
- Updated the ruleset JSON format and added SCHEMA version
- Updated cmdlets output to improve readability of recommendations

### Bug fixes

- Rules were revised and some were fixed
- Broken order of recommendations
- Error messages are not clear

### Known issues

- Invoke-SqlAssessment may crash with message "Missing data item 'FilterDefinition'" on some databases. If you face this issue, create a customization to disable the RedundantIndexes rule to disable it. See README.md to learn how to disable rules. We'll fix this issue with the next release.

- Assemblies providing methods for CLR probes should be recompiled for each new release of SQL Assessment API.
