#EPM Framework 5 Release Notes

Over 4.12.1 below, EPM Framework 5 includes the following updates (as per received feedback): Now compatible with last SQLServer PowerShell Module
https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-ps-module

Over 4.12.1 below, EPM Framework 4.12.2 includes the following updates (as per received feedback): Fixed collation issues on views and reports

Over 4.12 below, EPM Framework 4.12.1 includes the following updates (as per received feedback):
- Update documentation with PS security related information.
- Added existence check conditions to "4FixImportedPolicies" to avoid errors when not all default policies were imported.
- Fixed call to evaluation details sub-report not auto selecting policies, when called from "Failed Object Count by Policy Category" chart.
- Added better context in text pop-up in "Failed Object Count by Policy Category" chart.
- Added auto filtering by status when calling sub-report in "Failed Object Count by Policy Category" chart.
- Added auto filtering by status when calling sub-report in "Failed Policy % By Month" chart.
- Added policy filtering options in PolicyEvaluationDetails and PolicyEvaluationErrors sub-reports.
- Added call to evaluation details sub-report from "Objects in Failed State" value in the top-left of the Policy Dashboard.
- In PBM_Custom.zip, corrected script calling in job creation script.

Over 4.11 below, EPM Framework 4.12 includes the following updates (as per received feedback):
- Fixed issue with failed execution under SQL Agent PS job due to Write-Output.
- Fixed issue with Invoke-PolicyEvaluation and null values.
- Added resilience with different PS versions.
- Added server filtering options in PolicyEvaluationDetails and PolicyEvaluationErrors sub-reports.
- In PBM_Custom.zip, fixed condition for "Enterprise Features" policy that generated evaluation errors.

Over 4.1 below, EPM Framework 4.11 includes the following updates (as per received feedback):
- Fixed sub-reports deployment fail due to failed validation.
- Fixed issue in Data Loading Stored Procedure.

The EPM Framework 4.1 includes the following updates:
- New PS script Improved resilience when running from CMS hosted on SQL Server 2008, 2008R2, 2012 and 2014.
- Improved resilience when used with PS v2, v3 and v4.
- Improved Data Loading Stored Procedure, where some policy results might not be loaded (this has been identified as active since EPM v3).

The EPM Framework 4.0 includes the following updates:
- For enhanced support of large environments Reviewed database design, including views and indexing.
- Redesigned data load procedure.
- PowerShell execution now deletes XML files as soon as load is done - improves space usage on temp folder.
- Redesigned reports.

Tested from SQL Server 2000 to 2014.

Note: an upgrade script for all the relevant database objects is provided, supporting direct upgrade from v3 and v4. Please check the documentation for further information.

We are also providing a set of scripts as an extension to the base set of Microsoft provided policies, and assumes the user has previously imported these Microsoft provided policies, as described by the "Configure/Create Policies and Centralize on the Central Management Server" section of the EPM Configuration Documentation.
These scripts have some fixes for the Microsoft provided policies, and include extra policies:
- Determining the if SQL Server instances are at the recommended SP level. Note that the condition has to be updated with proper build numbers for the policy to be current.
- Determining the if SQL Server instances are at the recommended CU or Hotfix. Note that the condition has to be updated with proper build numbers for the policy to be current.
- Do I have log backups older than 24h?
- Do I have full backups on read-write, full RM databases?
- The Service accounts must not match between the several services, so what is the current status?
- Is AutoUpdateStats Disabled and AutoUpdateStats Async Enabled? Using SSMS gives you no warning if you’ve enabled this scenario, but if you think you are using * AutoUpdateStats Async, guess again.
- Check for database status that prevent database access, like Emergency mode or Suspect.
- Are there Non-unique clustered indexes? This might be something you wouldn’t want as a rule-of thumb.
- Are there tables with non-clustered IXs but no clustered IX? This might hint you to evaluate your application query activity against heaps.
- Do I have log growth in percentage, and it’s already over 1GB?
- Do I have more VLFs than my rule-of-thumb? This has a 100 VLF threshold – change as appropriate.
- Am I using Enterprise SKU features? Maybe I need to move a database to another server, and if it’s not an Enterprise Edition, so I must account for this?
- Is Maximum Server Memory set at default? You will want to set this setting different from default.
- Is Server Memory set at a fixed value?
- Are DB Compatibility levels same as engine version?
- Is Tempdb number of files appropriate? Regarding number of schedulers and if is multiple of 4?
- Do TempDB data file sizes match?
- Is MaxDOP setting at the recommended value?