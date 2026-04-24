# Release notes for SQL Assessment API

This article provides details about updates, improvements, and bug fixes for the current and previous versions of SQL Assessment API.

To start working with the API, install the SQL Assessment Extention to Azure Data Studio or utilize either the SqlServer module or SMO.

Installing SQL Assessment Extension: [SQL Server Assessment Extension for Azure Data Studio (Public Preview)](https://techcommunity.microsoft.com/t5/sql-server/released-sql-server-assessment-extension-for-azure-data-studio/ba-p/1470603)

Download: [SQL Assessment NuGet package](https://www.nuget.org/packages/Microsoft.SqlServer.Assessment)

Download: [Download SqlServer module](https://www.powershellgallery.com/packages/SqlServer)

Download: [SMO NuGet Package](https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects)

You can use GitHub issues to provide feedback to the product team.

## December 2022 - 1.1.17

Version: SqlServer PowerShell module, SqlManagementObjects (SMO) package: not updated

### What's new

- New rules:
  - 98 recommendations based on SQL Server error log content
  - Availability database count
  - Availability replica recovery health
  - Columnstore indexes with large page memory model
  - High SQL compilations frequency
  - High cursor requests frequency
  - Backup files on a separate physical location
  - Database mirroring
  - High deadlock frequency
  - SQL Server on a domain controller
  - Error log retention settings
  - High free space scans rate
  - Full scans vs index searches
  - High latch wait time
  - Excessive lazy writes
  - Lock requests per batch
  - Excessive lock waits
  - Memory grants pending
  - Non-default value for 'min server memory (MB)' option
  - Non-default value for 'nested triggers' option
  - High forwarded records rate
  - Sleeping sessions with open transactions
  - Orphaned server audit specification
  - Orphaned database audit specification
  - Low page life expectancy
  - High page lookups frequency
  - High page split rate
  - High SQL recompilation rate
  - Non-default value for 'remote access' option
  - Non-default value for 'remote login timeout (s)' option
  - Frequent scan point revalidations
  - Non-default value for 'server trigger recursion' option
  - Option 'show advanced options' is enabled
  - Tempdb data files initial size
  - High Wait for the worker
  - High transaction log disk response time
  - High Network IO
  - High non-Page latch waits
  - High Page IO latch waits
  - High Page Latch waits
  - High Workfiles Created per second
  - Low Worktables from Cache ratio
  - High Worktables Created per second
- New probes:
  - [Performance](./docs/Reference/Probes/Performance.md) probe type
  - BasicPerformance
  - AuditSpecs
  - ComputerSystem
  - DatabaseBackupsMedia
  - DatabaseMirroring
  - ErrorLog
  - ServerAudits
  - ServerDatabasesProperties
  - SysOpenTransactions
- New transformations:
  - [Performance](./docs/Reference/DataTransformation/performance.md) counter [data transformation](./docs/Customization/DataTransformation.md)

### Bug fixes and improvements

- Add [join](./docs/Reference/DataTransformation/aggregate.md#join) string [aggregate function](./docs/Reference/DataTransformation/aggregate.md#aggregate-functions) new parameters:
  - **distinct** specifies whether duplicates should be eliminated
  - **comparison** specifies [StringComparison](https://learn.microsoft.com/dotnet/api/system.stringcomparison) used by the aggregate function
- Add **ag_replica_recovery_health** variable to the **AGConfiguration** probe
- Add **age_days** to **ErrorLogInfo** probe
- Add **remote_access**, **remote_login_timeout**, **server_trigger_recursion**, and **default_language** to **SysConfiguration** probe
- Fix warning message on missing permissions and other requirements
- Fix help link for DbSpaceAvailable check ([GitHub #1035](https://github.com/microsoft/sql-server-samples/issues/1035))
- Fix falsely flagging deprecated features in job steps ([GitHub #1025](https://github.com/microsoft/sql-server-samples/issues/1025))
- Fix configured to active value comparison for Max and Min server memory
- Fix duplicate messages for Azure disk checks
- Fix TF834 check triggered when no columnstore index is in use
- Remove Server target type filter from probes which work for databases

## July 2022 - 1.1.9

Version: SqlServer PowerShell module: [22.0.30-preview](https://www.powershellgallery.com/packages/SqlServer/22.0.30-preview), SqlManagementObjects (SMO) package: not updated

### What's new

- New rules:
  - Access check cache options ratio
  - Availability group listener network mode
  - Availability group failure-condition level
  - Availability group health check timeout
  - Availability replica connection state
  - Availability replica synchronization health
  - Availability database automatic failover readiness
  - Availability database joined state
  - Azure data disk striping
  - Database mirroring endpoint encryption
  - Database with unavailable state
  - Maximum number of Availability Groups
  - Not supported value for 'default full-text language' option
  - Non-default values for access check cache options
  - Option 'disallow results from triggers' is disabled
  - Setting 'Autogrow' for data files
  - Tables with more indexes than columns
  - TempDb and user databases should not share volumes
- New Probes:
  - AGConfiguration
  - AGDatabases
  - AGEndpoints
  - AGListener
  - DatabaseSharedVolumes
  - DatabasesState
  - SysFullTextLanguages
  - TablesInformation
- Added 'MaxCheckResults' configuration option to limit assessment output

### Bug fixes and improvements

- The following rules are not run for Linux targets now:
  - Indexes keys with more than @{threshold} bytes
  - MAXDOP set in accordance with CPU count
  - 'STRelate' and 'STAsBinary' functions unexpected results due to TF 6533
  - TF 4199 enables query optimizer fixes
  - TF 6532 enables performance improvements for spatial data
  - TF 8015 disables auto-detection and NUMA setup
  - TF 8744 disables pre-fetching for Nested Loop operator
  - TF 9347 disables batch mode for sort operator
  - TF 9349 disables batch mode for top N sort operator
  - TF 9389 enables dynamic memory grant for batch mode operators
  - TF 9476 causes SQL Server to generate plan using Simple Containment assumption
  - TF 9481 enables Legacy CE model
- Improved performance of idex related probes and checks
- Improved performance of other probes
- Affinity 64 and Affinity 64 IO masks are checked on 64-bit platforms only
- Instant File Initialization check is not run for SQL Server 2016 without service packs
- Fixed requirements processing for checks
- 'Max allowed memory' and 'Max server memory exceeds system memory' checks are not run for SQL Server Managed Instance now
- Updated 'Latest cumulative update' check
- 'Stored procedure naming' check severity changed to Low
- 'Uncompressed database tables and indexes' gives more details in the message
- 'SQL logins have weak passwords' now checks for empty passwords and password equal to login
- Non-default value for 'common criteria compliance enabled' option
- Option 'backup compression default' is disabled
- Replaced DatabaseFileLocation probe with DatabaseMasterFiles in the following rules:
  - Azure disk caching for data files
  - Azure disk caching for transaction logs
  - Data files on Azure data disks
  - Storage spaces disk column count
  - Tempdb files on Azure temp drive
  - Use premium SSDs for SQL Server data files
- Improved probes
  - OsSysMemory
  - ServerProperties
  - TopUncompressedTables
  - ServerProperties
  - WeakPassword
- Removed rules:
  - LoginEqPassword
  - LoginNoPassword

## December 2021 - 1.1.0

Version: SqlServer PowerShell module, SqlManagementObjects (SMO) package: not updated

### What's new

- Added .NET 451 support
- The SQL Assessment API engine accepts a 'DbConnection' object as a target specification
- Added the 'CloneConnection' property to the engine configuration
- New rules:
  - Cache needs to be cleared of single-use plans
  - Instant file initialization (IFI) is disabled
  - Tempdb files on Azure temp drive
  - Error log and default trace files on Azure data disk
  - Data files on Azure data disks
  - Storage spaces disk column count
  - Azure disk caching for data files
  - Azure disk caching for transaction logs
  - Database default locations
  - Lock pages in memory
  - Use premium SSDs for SQL Server data files
- New probes:
  - ServiceInfo returns the state of selected Windows service (WMI)
  - AzStorage returns information about disks and volumes on the Azure VM hosting the target object (WMI)
  - AzDiskMetadata probe returns information about storage devices present on the Azure VM hosting the target object (IMDS)
  - DatabaseFilesLocation lists volumes hosting database files (T-SQL)
  - DbFilesDefaultLocation returns the default data file location for new databases (registry)
- Added 'sql_memory_model' to the 'SysDmOsSysInfo' probe
- Added 'expandData' transformation
- Added support for direct WMI and registry access
- Added support for Azure Instance Metadata
- Added custom data sources to the assessment target specification
- Added CIM namespace support to WMI probes
- Added support for PowerShell scripts returning arrays
- Added the 'timeout' property to SQL probes for long-running queries (default value is 30 seconds)

### Bug fixes and improvements

- Changed severity levels to Information, Low, Medium, and High
- The SQL Assessment API engine can now detect target's version, platform, engine edition, machine type, and server name automatically
- Improved performance of the 'DeprecatedFeaturesInModules' check. Now it groups results by feature
- Fixed 'CpuUsage' returning 'null' for a short time after a restart of SQL Server
- Fixed crash on missing 'rules' ruleset property
- The 'ErrorLogInfo' probe now uses a temporary table instead of direct stored procedure call
- Fixed missing warnings on inaccessible WMI, registry, or Azure data
- 'LoginNoPassword' and 'LoginEqPassword' checks are now merged with 'WeakPassword'
- 'PlansUseRatio' check now uses the 'optimize_for_ad_hoc_workloads' configuration option
- Azure-related probes now use Azure Instance Metadata directly or emulated with Azure Resource Graph
- 'AgentSvcStopped', 'BrowserSvcStopped', 'DtcSvcStopped', 'FullTextSvcStopped', and 'RsSvcStopped' checks now use the WMI-based 'ServiceInfo' probe instead of the 'ServiceControl' PowerShell script
- 'UnusedIndexes' check now displays the affected table name
- NTFS Block size check now uses the device ID instead of the volume name
- 'TempDBFilesMultiple4' message was updated with more details
- A number of checks were made available for Linux
- 'OnPremises' engine edition group was renamed to 'SqlServer'
- 'AzureSQL' VM type was renamed to 'AzureVM'

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
