# SQL Assessment API Quick Start Guide

Assess your SQL Server configuration in 2 simple steps.

## 1. Setup

Install the [PowerShell SqlServer module](https://www.powershellgallery.com/packages/SqlServer) using the following command.

```PowerShell
Install-Module -Name SqlServer -AllowClobber
```

## 2. Invoke assessment

To invoke an assessment against a local SQL Server instance, run the following command.

```PowerShell
Get-SqlInstance -ServerInstance 'localhost' | Invoke-SqlAssessment
```

Sample result:

```PowerShell
PS:> Get-SqlInstance -ServerInstance localhost | Invoke-SqlAssessment

   TargetPath: Server[@Name='LOCAL']

Sev. Message                                                            Check ID              Origin
---- -------                                                            --------              ------
Info Enable trace flag 834 to use large-page allocations to improve     TF834                 Microsoft Ruleset 0.1.202
     analytical and data warehousing workloads.
Low  Detected deprecated or discontinued feature uses: String literals  DeprecatedFeatures    Microsoft Ruleset 0.1.202
     as column aliases, syscolumns, sysusers, SET FMTONLY ON, XP_API,
     Table hint without WITH, More than two-part column name. We
     recommend to replace them with features actual for SQL Server
     version 14.0.1000.
Medi Amount of single use plans in cache is high (100%). Consider       PlansUseRatio         Microsoft Ruleset 0.1.202
     enabling the Optimize for ad hoc workloads setting on heavy OLTP
     ad-hoc workloads to conserve resources.
...
```

In the results, you will see that each rule has some properties (not the full list):

- Severity (info, low, medium, high)
- Message property explains the recommendation but if you need more info, there is a HelpLink property that points at documentation on the subject.
- Origin shows which ruleset and version the recommendation is coming from

See [ruleset.json](./ruleset.json) for a full list of rules and properties.

If you want to get recommendations for all databases on the local instance, run this command.

```PowerShell
Get-SqlDatabase -ServerInstance 'localhost' | Invoke-SqlAssessment
```

## Learn more about SQL Assessment API

To learn more about the SQL Assessment API such as customizing and extending rulesets, saving results to a table, etc., visit:

- Docs online page for SQL Assessment API PowerShell cmdlets: https://docs.microsoft.com/sql/sql-assessment-api/sql-assessment-api-overview
- [SQL Assessment User Guide](UserGuide/README.md)
- SQL Assessment API Tutorial notebook: [SQLAssessmentAPITutorialNotebook.ipynb](./notebooks/SQLAssessmentAPITutorialNotebook.ipynb)
- Azure Data Studio extension: https://techcommunity.microsoft.com/t5/sql-server/released-sql-server-assessment-extension-for-azure-data-studio/ba-p/1470603
