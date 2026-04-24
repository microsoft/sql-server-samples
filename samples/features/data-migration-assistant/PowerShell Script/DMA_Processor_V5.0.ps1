#This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
#THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#We grant you a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute
#the object code form of the Sample Code, provided that you agree:
#(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
#(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
#(iii) to indemnify, hold harmless, and defend Us and our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
# -----------------------------------------------------------------------------
#
# Script: DMA_Processor.ps1
# Author: Chris Lound - Senior Premier Field Engineer - Data Platform.
# Date: 08/02/2017
# Version:  5.0
# Synopsis: Create reporting objects and loads JSON files from DMA output folder into SQL server
# Keywords:
# Notes:  A processed folder is created in the root folder of the folder containing the DMA JSON output (user specified).  Script currently only supports windows authentication to SQL Server.
# Comments:
# 1.0 	Initial Release - 22/11/2016
# 2.0   Refactored JSON shredder for SQL2014 and below.  Made this the only shredding function by removing the SQL2016 dependency
# 3.0   Built in weighted breaking changes.  Added table to support breaking change weighting and updated view to use it for reporting.  Also removed Azure Artifacts
# 3.1   Change importdate type to datetime.  Added DBOwner column for reportdata table. - 16/02/2017
# 4.0   Added DMAWarehouse objects. Cleaned up output into console
# 4.1   Added Warehouse views, AssessmentTarget and AssessmentName properties and dependants
# 5.0   Added support for feature parity for azure targets (new table, table type, stored procedure, datatable (ps), shredding loop (ps).
#       Added error handling for failed dataset fills.  Added support for only moving files when they are actually processed.  if they fail they dont get moved.
#       Added option to create data warehouse
#       Altered UpgradeSuccessRanking view to exclude TargetCompatibilityMode of 'NA' (Azure migrations)
#       REMOVED data warehouse scripts from this specific script version
#       Split UpgradeSuccessRanking views into 2, 1 for onprem and 1 for azure to fix assessment counts in powerbi

#------------------------------------------------------------------------------------ CREATE FUNCTIONS -------------------------------------------------------------------------------------


#Import JSON to SQL on prem or azure
function dmaProcessor
{
param(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $serverName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $databaseName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $jsonDirectory,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("SQLServer")]
    [string] $processTo
)

    #Create database objects
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
    $srv = New-Object Microsoft.SqlServer.Management.SMO.Server($serverName)

    #create reporting database
    $dbCheck = $srv.Databases | Where {$_.Name -eq "$databaseName"} | Select Name
    if(!$dbCheck)
    {
        $db = New-Object Microsoft.SqlServer.Management.Smo.Database ($srv, $databaseName)

        $db.Create()

        Write-Host("Database $databaseName created successfully") -ForegroundColor Green
    }
    else
    {
            $db=$srv.Databases.Item($databaseName)
            Write-Host ("Database $databaseName already exists") -ForegroundColor Yellow
    }

    #create ReportData table
    $tableCheck = $db.Tables | Where {$_.Name -eq "ReportData"}
    if(!$tableCheck)
    {
        $ReportDatatbl = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "ReportData")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "InstanceName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Name", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "SizeMB", [Microsoft.SqlServer.Management.Smo.DataType]::Decimal(6, 38))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "SourceCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "TargetCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ChangeCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(20))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col16 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImpactedObjectName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col17 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col18 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col19 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "DBOwner", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col20 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "AssessmentTarget", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col21 = New-Object Microsoft.SqlServer.Management.Smo.Column($ReportDatatbl, "AssessmentName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))

        $ReportDatatbl.Columns.Add($col1)
        $ReportDatatbl.Columns.Add($col2)
        $ReportDatatbl.Columns.Add($col3)
        $ReportDatatbl.Columns.Add($col4)
        $ReportDatatbl.Columns.Add($col5)
        $ReportDatatbl.Columns.Add($col6)
        $ReportDatatbl.Columns.Add($col7)
        $ReportDatatbl.Columns.Add($col8)
        $ReportDatatbl.Columns.Add($col9)
        $ReportDatatbl.Columns.Add($col10)
        $ReportDatatbl.Columns.Add($col11)
        $ReportDatatbl.Columns.Add($col12)
        $ReportDatatbl.Columns.Add($col13)
        $ReportDatatbl.Columns.Add($col14)
        $ReportDatatbl.Columns.Add($col15)
        $ReportDatatbl.Columns.Add($col16)
        $ReportDatatbl.Columns.Add($col17)
        $ReportDatatbl.Columns.Add($col18)
        $ReportDatatbl.Columns.Add($col19)
        $ReportDatatbl.Columns.Add($col20)
        $ReportDatatbl.Columns.Add($col21)

        $ReportDatatbl.Create()
        Write-Host ("Table ReportData created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Table ReportData already exists") -ForegroundColor Yellow
    }

    #create AzureFeatureParity table
    $tableCheck2 = $db.Tables | Where {$_.Name -eq "AzureFeatureParity"}
    if(!$tableCheck2)
    {
        $AzureReportDatatbl = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "AzureFeatureParity")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ServerName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Version", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(10))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "FeatureParityCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "RuleID", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImpactedDatabasename", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureReportDatatbl, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)

        $AzureReportDatatbl.Columns.Add($col1)
        $AzureReportDatatbl.Columns.Add($col2)
        $AzureReportDatatbl.Columns.Add($col3)
        $AzureReportDatatbl.Columns.Add($col4)
        $AzureReportDatatbl.Columns.Add($col5)
        $AzureReportDatatbl.Columns.Add($col6)
        $AzureReportDatatbl.Columns.Add($col7)
        $AzureReportDatatbl.Columns.Add($col8)
        $AzureReportDatatbl.Columns.Add($col9)
        $AzureReportDatatbl.Columns.Add($col10)
        $AzureReportDatatbl.Columns.Add($col11)
        $AzureReportDatatbl.Columns.Add($col12)
        $AzureReportDatatbl.Columns.Add($col13)
        $AzureReportDatatbl.Columns.Add($col14)
        $AzureReportDatatbl.Columns.Add($col15)

        $AzureReportDatatbl.Create()
        Write-Host ("Table AzureFeatureParity created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Table AzureFeatureParity already exists") -ForegroundColor Yellow
    }

    #create BreakingChangeWeighting table
    $tableCheck3 = $db.Tables | Where {$_.Name -eq "BreakingChangeWeighting"}
    if(!$tableCheck3)
    {
        $BreakingChangetbl = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "BreakingChangeWeighting")

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(36))
        $col1.Nullable = $false
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(150))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "Effort", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "FixTime", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "Cost", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($BreakingChangetbl, "ChangeRank", [Microsoft.SqlServer.Management.Smo.DataType]::TinyInt)
        $Col6.Computed = $True
        $Col6.ComputedText = "(Effort + FixTime + Cost) / 3"

        $BreakingChangetbl.Columns.Add($col1)
        $BreakingChangetbl.Columns.Add($col2)
        $BreakingChangetbl.Columns.Add($col3)
        $BreakingChangetbl.Columns.Add($col4)
        $BreakingChangetbl.Columns.Add($col5)
        $BreakingChangetbl.Columns.Add($col6)

        $BreakingChangetbl.Create()

        $PK = New-Object Microsoft.SqlServer.Management.Smo.Index($BreakingChangetbl,"PK_BreakingChangeWeighting_RuleId")
        $PK.IndexKeyType = "DriPrimaryKey"

        $IdxCol = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($PK, $col1.Name)
        $PK.IndexedColumns.Add($IdxCol)
        $PK.Create()

        Write-Host ("Table BreakingChangeWeighting created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Table BreakingChangeWeighting already exists") -ForegroundColor Yellow
    }

    #Create views
    $vwCheck1 = $db.Views | Where {$_.Name -eq "DatabaseCategoryRanking"}
    if(!$vwCheck1)
    {
        $vwDatabaseCategoryRanking = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $db, "DatabaseCategoryRanking", "dbo"

        $vwDatabaseCategoryRanking.TextHeader = "CREATE VIEW [dbo].[DatabaseCategoryRanking] AS"
        $vwDatabaseCategoryRanking.TextBody=@"
WITH DatabaseRanking
AS
(
SELECT	[Name]
		,ChangeCategory
		,COUNT(*) AS "NumberOfIssues"
		,(CONVERT(NUMERIC(5,2),COUNT(*))/(SELECT CONVERT(NUMERIC(5,2),COUNT(*)) FROM reportdata r2 Where r1.[name] = r2.[name])) * 100 AS "ChangeCategoryPercentage"
FROM	reportdata r1
GROUP BY [Name], ChangeCategory
)
SELECT	[Name] AS "DatabaseName"
	,ChangeCategory
	,ChangeCategoryPercentage
FROM DatabaseRanking;
"@

        $vwDatabaseCategoryRanking.Create()
        Write-Host ("View DatabaseCategoryRanking created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("View DatabaseCategoryRanking already exists") -ForegroundColor Yellow
    }

    $vwCheck2 = $db.Views | Where {$_.Name -eq "UpgradeSuccessRanking"}
    if(!$vwCheck2)
    {
        $vwUpgradeSuccessRanking = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $db, "UpgradeSuccessRanking", "dbo"

        $vwUpgradeSuccessRanking.TextHeader = "CREATE VIEW [dbo].[UpgradeSuccessRanking] AS"
        $vwUpgradeSuccessRanking.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN SUM(ChangeRank) END ,0) AS 'BreakingChange'
		--,COALESCE(CASE changecategory WHEN 'NotDefined' THEN COUNT(*) END,0) AS 'NotDefined'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM reportdata rd
LEFT JOIN BreakingChangeWeighting bcw
ON rd.RuleId = bcw.ruleid
WHERE changecategory != 'NotDefined'
and TargetCompatibilityLevel != 'NA'
GROUP BY InstanceName,name, changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		--,MAX(NotDefined) AS 'NotDefined'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY InstanceName,name, TargetCompatibilityLevel
),
IssueTotaled
AS
(
SELECT	*, behaviorchange + deprecatedcount + breakingchange + MigrationBlocker AS 'Total'
FROM	distinctissues
),
RankedDatabases
AS
(
SELECT	InstanceName
		,Name
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		--,CAST(100-((NotDefined + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'NotDefined'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		--,CASE  WHEN NotDefined > 0 THEN NotDefined ELSE 1 END AS "NotDefined"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker"
FROM	RankedDatabases
"@

        $vwUpgradeSuccessRanking.Create()
        Write-Host ("View UpgradeSuccessRanking created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("View UpgradeSuccessRanking already exists") -ForegroundColor Yellow
    }

    $vwCheck3 = $db.Views | Where {$_.Name -eq "UpgradeSuccessRanking_OnPrem"}
    if(!$vwCheck3)
    {
        $vwUpgradeSuccessRankingop = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $db, "UpgradeSuccessRanking_OnPrem", "dbo"

        $vwUpgradeSuccessRankingop.TextHeader = "CREATE VIEW [dbo].[UpgradeSuccessRanking_OnPrem] AS"
        $vwUpgradeSuccessRankingop.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN SUM(ChangeRank) END ,0) AS 'BreakingChange'
FROM	ReportData rd
LEFT JOIN BreakingChangeWeighting bcw
	ON rd.RuleId = bcw.ruleid
WHERE	ChangeCategory != 'NotDefined'
	AND TargetCompatibilityLevel != 'NA'
	AND AssessmentTarget IN ('SqlServer2012', 'SqlServer2014', 'SqlServer2016')
GROUP BY InstanceName,name, changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
FROM	issuecount
GROUP BY InstanceName,name, TargetCompatibilityLevel
),
IssueTotaled
AS
(
SELECT	*, behaviorchange + deprecatedcount + breakingchange AS 'Total'
FROM	distinctissues
),
RankedDatabases
AS
(
SELECT	InstanceName
		,Name
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
FROM	RankedDatabases

"@

        $vwUpgradeSuccessRankingop.Create()
        Write-Host ("View UpgradeSuccessRanking_OnPrem created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("View UpgradeSuccessRanking_OnPrem already exists") -ForegroundColor Yellow
    }


    $vwCheck4 = $db.Views | Where {$_.Name -eq "UpgradeSuccessRanking_Azure"}
    if(!$vwCheck4)
    {
        $vwUpgradeSuccessRankingaz = New-Object -TypeName Microsoft.SqlServer.Management.SMO.View -argumentlist $db, "UpgradeSuccessRanking_Azure", "dbo"

        $vwUpgradeSuccessRankingaz.TextHeader = "CREATE VIEW [dbo].[UpgradeSuccessRanking_Azure] AS"
        $vwUpgradeSuccessRankingaz.TextBody=@"
WITH issuecount
AS
(
-- currently doesn't take into account diminishing returns for repeating issues
-- removed NotDefined as these are for feature parity, not migration blockers and should therefore be excluded in calculations
SELECT	InstanceName
		,NAME
		,TargetCompatibilityLevel
		,COALESCE(CASE changecategory WHEN 'BehaviorChange' THEN COUNT(*) END,0) AS 'BehaviorChange'
		,COALESCE(CASE changecategory WHEN 'Deprecated' THEN COUNT(*) END,0) AS 'DeprecatedCount'
		,COALESCE(CASE changecategory WHEN 'BreakingChange' THEN SUM(ChangeRank) END ,0) AS 'BreakingChange'
		,COALESCE(CASE changecategory WHEN 'MigrationBlocker' THEN COUNT(*) END,0) AS 'MigrationBlocker'
FROM	ReportData rd
LEFT JOIN BreakingChangeWeighting bcw
	ON	rd.RuleId = bcw.ruleid
WHERE	changecategory != 'NotDefined'
	AND TargetCompatibilityLevel != 'NA'
	AND AssessmentTarget = 'AzureSQLDatabaseV12'
GROUP BY InstanceName, [Name], changecategory, TargetCompatibilityLevel
),
distinctissues
AS
(
SELECT	InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,MAX(BehaviorChange) AS 'BehaviorChange'
		,MAX(DeprecatedCount) AS 'DeprecatedCount'
		,MAX(BreakingChange) AS 'BreakingChange'
		,MAX(MigrationBlocker) AS 'MigrationBlocker'
FROM	issuecount
GROUP BY InstanceName, [Name], TargetCompatibilityLevel
),
IssueTotaled
AS
(
SELECT	*, behaviorchange + deprecatedcount + breakingchange + MigrationBlocker AS 'Total'
FROM	distinctissues
),
RankedDatabases
AS
(
SELECT	InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CAST(100-((BehaviorChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BehaviorChange'
		,CAST(100-((DeprecatedCount + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'DeprecatedCount'
		,CAST(100-((BreakingChange + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'BreakingChange'
		,CAST(100-((MigrationBlocker + 0.00) / (total + 0.00)) * 100 AS DECIMAL(5,2)) AS 'MigrationBlocker'
FROM	IssueTotaled
)
-- This section will ensure that if there are 0 issues in a category we return 1.  This ensures the reports show data
SELECT	 InstanceName
		,[Name]
		,TargetCompatibilityLevel
		,CASE  WHEN BehaviorChange > 0 THEN BehaviorChange ELSE 1 END AS "BehaviorChange"
		,CASE  WHEN DeprecatedCount > 0 THEN DeprecatedCount ELSE 1 END AS "DeprecatedCount"
		,CASE  WHEN BreakingChange > 0 THEN BreakingChange ELSE 1 END AS "BreakingChange"
		,CASE  WHEN MigrationBlocker > 0 THEN MigrationBlocker ELSE 1 END AS "MigrationBlocker"
FROM	RankedDatabases
"@

        $vwUpgradeSuccessRankingaz.Create()
        Write-Host ("View UpgradeSuccessRanking_Azure created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("View UpgradeSuccessRanking_Azure already exists") -ForegroundColor Yellow
    }

    #Create Table Types
    $ttCheck = $db.UserDefinedTableTypes | Where {$_.Name -eq "JSONResults"}
    if(!$ttCheck)
    {
        $JSONResultstt = New-Object -TypeName Microsoft.SqlServer.Management.Smo.UserDefinedTableType -ArgumentList $db, "JSONResults"

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "InstanceName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Name", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "SizeMB", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "SourceCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "TargetCompatibilityLevel", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ChangeCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(20))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "RuleId", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col16 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImpactedObjectName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(255))
        $col17 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col18 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col19 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "DBOwner", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col20 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "AssessmentTarget", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col21 = New-Object Microsoft.SqlServer.Management.Smo.Column($JSONResultstt, "AssessmentName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))

        $JSONResultstt.Columns.Add($col1)
        $JSONResultstt.Columns.Add($col2)
        $JSONResultstt.Columns.Add($col3)
        $JSONResultstt.Columns.Add($col4)
        $JSONResultstt.Columns.Add($col5)
        $JSONResultstt.Columns.Add($col6)
        $JSONResultstt.Columns.Add($col7)
        $JSONResultstt.Columns.Add($col8)
        $JSONResultstt.Columns.Add($col9)
        $JSONResultstt.Columns.Add($col10)
        $JSONResultstt.Columns.Add($col11)
        $JSONResultstt.Columns.Add($col12)
        $JSONResultstt.Columns.Add($col13)
        $JSONResultstt.Columns.Add($col14)
        $JSONResultstt.Columns.Add($col15)
        $JSONResultstt.Columns.Add($col16)
        $JSONResultstt.Columns.Add($col17)
        $JSONResultstt.Columns.Add($col18)
        $JSONResultstt.Columns.Add($col19)
        $JSONResultstt.Columns.Add($col20)
        $JSONResultstt.Columns.Add($col21)

        $JSONResultstt.Create()
        Write-Host ("Table Type JSONResults created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Table Type JSONResults already exists") -ForegroundColor Yellow
    }

    $ttCheck2 = $db.UserDefinedTableTypes | Where {$_.Name -eq "AzureFeatureParityResults"}
    if(!$ttCheck2)
    {
        $AzureParityResultstt = New-Object -TypeName Microsoft.SqlServer.Management.Smo.UserDefinedTableType -ArgumentList $db, "AzureFeatureParityResults"

        $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImportDate", [Microsoft.SqlServer.Management.Smo.DataType]::DateTime)
        $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ServerName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Version", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15))
        $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Status", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(10))
        $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Category", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Severity", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "FeatureParityCategory", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))
        $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "RuleID", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))
        $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Title", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col10 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Impact", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(1000))
        $col11 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "Recommendation", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col12 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "MoreInfo", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)
        $col13 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImpactedDatabasename", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(128))
        $col14 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImpactedObjectType", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(30))
        $col15 = New-Object Microsoft.SqlServer.Management.Smo.Column($AzureParityResultstt, "ImpactDetail", [Microsoft.SqlServer.Management.Smo.DataType]::VarCharMax)


        $AzureParityResultstt.Columns.Add($col1)
        $AzureParityResultstt.Columns.Add($col2)
        $AzureParityResultstt.Columns.Add($col3)
        $AzureParityResultstt.Columns.Add($col4)
        $AzureParityResultstt.Columns.Add($col5)
        $AzureParityResultstt.Columns.Add($col6)
        $AzureParityResultstt.Columns.Add($col7)
        $AzureParityResultstt.Columns.Add($col8)
        $AzureParityResultstt.Columns.Add($col9)
        $AzureParityResultstt.Columns.Add($col10)
        $AzureParityResultstt.Columns.Add($col11)
        $AzureParityResultstt.Columns.Add($col12)
        $AzureParityResultstt.Columns.Add($col13)
        $AzureParityResultstt.Columns.Add($col14)
        $AzureParityResultstt.Columns.Add($col15)

        $AzureParityResultstt.Create()
        Write-Host ("Table Type AzureFeatureParityResults created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Table Type AzureFeatureParityResults already exists") -ForegroundColor Yellow
    }

    #Create Stored Procedures
    $procCheck = $db.StoredProcedures | Where {$_.Name -eq "JSONResults_Insert"}
    if(!$procCheck)
    {
        $JSONResults_Insert = New-Object -TypeName Microsoft.SqlServer.Management.Smo.StoredProcedure -ArgumentList $db, "JSONResults_Insert", "dbo"

        $JSONResults_Insert.TextHeader = "CREATE PROCEDURE dbo.JSONResults_Insert @JSONResults JSONResults READONLY AS"
        $JSONResults_Insert.TextBody = @"
BEGIN

INSERT INTO dbo.ReportData (ImportDate, InstanceName, [Status], [Name], SizeMB, SourceCompatibilityLevel, TargetCompatibilityLevel, Category, Severity, ChangeCategory, RuleId, Title, Impact, Recommendation, MoreInfo, ImpactedObjectName, ImpactedObjectType, ImpactDetail, DBOwner, AssessmentTarget, AssessmentName)
SELECT ImportDate, InstanceName, [Status], [Name], SizeMB, SourceCompatibilityLevel, TargetCompatibilityLevel, Category, Severity, ChangeCategory, RuleId, Title, Impact, Recommendation, MoreInfo, ImpactedObjectName, ImpactedObjectType, ImpactDetail, DBOwner, AssessmentTarget, AssessmentName
FROM @JSONResults

END
"@

        $JSONResults_Insert.Create()
        Write-Host ("Stored Procedure JSONNResults_Insert created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Stored Procedure JSONNResults_Insert already exists") -ForegroundColor Yellow
    }

    $procCheck2 = $db.StoredProcedures | Where {$_.Name -eq "AzureFeatureParityResults_Insert"}
    if(!$procCheck2)
    {
        $AzureFeatureParityResults_Insert = New-Object -TypeName Microsoft.SqlServer.Management.Smo.StoredProcedure -ArgumentList $db, "AzureFeatureParityResults_Insert", "dbo"

        $AzureFeatureParityResults_Insert.TextHeader = "CREATE PROCEDURE dbo.AzureFeatureParityResults_Insert @AzureFeatureParityResults AzureFeatureParityResults READONLY AS"
        $AzureFeatureParityResults_Insert.TextBody = @"
BEGIN

INSERT INTO dbo.AzureFeatureParity (ImportDate, ServerName, Version, Status, Category, Severity, FeatureParityCategory, RuleID, Title, Impact, Recommendation, MoreInfo, ImpactedDatabasename, ImpactedObjectType, ImpactDetail)
SELECT ImportDate, ServerName, Version, Status, Category, Severity, FeatureParityCategory, RuleID, Title, Impact, Recommendation, MoreInfo, ImpactedDatabasename, ImpactedObjectType, ImpactDetail
FROM @AzureFeatureParityResults

END
"@

        $AzureFeatureParityResults_Insert.Create()
        Write-Host ("Stored Procedure AzureFeatureParityResults_Insert created successfully") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Stored Procedure AzureFeatureParityResults_Insert already exists") -ForegroundColor Yellow
    }

    # END CREATE DATABASE OBJECTS #


    #Make processed directory inside the folder that contains the json files
    if(!$jsonDirectory.EndsWith("\"))
    {
        $jsonDirectory = "$jsonDirectory\"
    }
    $processedDir = "$jsonDirectory`Processed"

    if((Test-Path $processedDir) -eq $false)
    {
        new-item $processedDir -ItemType directory
        Write-Host ("Processed directory created successfully at [$processDir]") -ForegroundColor Green
    }
    else
    {
        Write-Host ("Processed directory already exists") -ForegroundColor Yellow
    }
   
    # if there are no files to process stop importer
    $FileCheck = Get-ChildItem $jsonDirectory -Filter *.JSON
    if($FileCheck.Count -eq 0)
    {
        Write-Host ("There are no JSON assessment files to process") -ForegroundColor Yellow
        Break
    }


    $connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;"

    #Populate the breaking change reference data
    $RefDataCheck = $db.Tables | Where {$_.Name -eq "BreakingChangeWeighting"} | Select RowCount
    if($RefDataCheck.RowCount -eq 0)
    {

        #populate static data into BreakingChangeWeighting

        $CommandText = @'
INSERT INTO BreakingChangeWeighting VALUES ('Microsoft.Rules.Data.Upgrade.UR00001','Syntax issue on the source server',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00006','BACKUP LOG WITH NO_LOG|TRUNCATE_ONLY statements are not supported',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00007','BACKUP/RESTORE TRANSACTION statements are deprecated or discontinued',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00013','COMPUTE clause is not allowed in database compatibility 110',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00020','Read-only databases cannot be upgraded',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00021','Verify all filegroups are writeable during the upgrade process',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00023','SQL Server native SOAP support is discontinued in SQL Server 2014 and above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00044','Remove user-defined type (UDT)s named after the reserved GEOMETRY and GEOGRAPHY data types',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00050','Table hints in indexed view definitions are ignored in compatibility mode 80 and are not allowed in compatibility mode 90 or above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00058','After upgrade, new reserved keywords cannot be used as identifiers',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00062','Tables and Columns named NEXT may lead to an error using compatibility Level 110 and above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00086','XML is a reserved system type name',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00110','New column in output of sp_helptrigger may impact applications',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00113','SQL Mail has been discontinued',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00300','Remove the use of PASSWORD in BACKUP command',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00301','WITH CHECK OPTION is not supported in views that contain TOP in compatibility mode 90 and above',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00302','Discontinued DBCC commands referenced in your T-SQL objects',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00308','Legacy style RAISERROR calls should be replaced with modern equivalents',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00311','Detected statements that reference removed system stored procedures that are not available in database compatibility level 100 and higher',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00318','FOR BROWSE is not allowed in views in 90 or later compatibility modes',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00321','Non ANSI style left outer join usage',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00322','Non ANSI style right outer join usage',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00326','Constant expressions are not allowed in the ORDER BY clause in 90 or later compatibility modes',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00332','FASTFIRSTROW table hint usage',1,1,1),
('Microsoft.Rules.Data.Upgrade.UR00336','Certain XPath functions are not allowed in OPENXML queries',1,1,1)
'@

        $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $conn.Open() | Out-Null

        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.Connection = $conn
        $cmd.CommandType = [System.Data.CommandType]"Text"
        $cmd.CommandText= $CommandText

        $ds=New-Object system.Data.DataSet
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
        $da.fill($ds)
        $conn.Close()
    }

    # importer for SQL2014 and previous versions. Done via PowerShell
    Get-ChildItem $jsonDirectory -Filter *.JSON |
    Foreach-Object {

        $filename = $_.FullName

        #ReportData datatable
        $datatable = New-Object -type system.data.datatable
        $datatable.columns.add("ImportDate",[DateTime]) | Out-Null
        $datatable.columns.add("InstanceName",[String]) | Out-Null
        $datatable.columns.add("Status",[String]) | Out-Null
        $datatable.columns.add("Name",[String]) | Out-Null
        $datatable.columns.add("SizeMB",[Decimal]) | Out-Null
        $datatable.columns.add("SourceCompatibilityLevel",[String]) | Out-Null
        $datatable.columns.add("TargetCompatibilityLevel",[String]) | Out-Null
        $datatable.columns.add("Category",[String]) | Out-Null
        $datatable.columns.add("Severity",[String]) | Out-Null
        $datatable.columns.add("ChangeCategory",[String]) | Out-Null
        $datatable.columns.add("RuleId",[String]) | Out-Null
        $datatable.columns.add("Title",[String]) | Out-Null
        $datatable.columns.add("Impact",[String]) | Out-Null
        $datatable.columns.add("Recommendation",[String]) | Out-Null
        $datatable.columns.add("MoreInfo",[String]) | Out-Null
        $datatable.columns.add("ImpactedObjectName",[String]) | Out-Null
        $datatable.columns.add("ImpactedObjectType",[String]) | Out-Null
        $datatable.columns.add("ImpactDetail",[string]) | Out-Null
        $datatable.columns.add("DBOwner",[string]) | Out-Null
        $datatable.columns.add("AssessmentTarget",[string]) | Out-Null
        $datatable.columns.add("AssessmentName",[string]) | Out-Null

        #AzureFeatureParity datatable
        $azuredatatable = New-Object -type system.data.datatable
        $azuredatatable.columns.add("ImportDate",[DateTime]) | Out-Null
        $azuredatatable.columns.add("ServerName",[String]) | Out-Null
        $azuredatatable.columns.add("Version",[String]) | Out-Null
        $azuredatatable.columns.add("Status",[String]) | Out-Null
        $azuredatatable.columns.add("Category",[String]) | Out-Null
        $azuredatatable.columns.add("Severity",[String]) | Out-Null
        $azuredatatable.columns.add("FeatureParityCategory",[String]) | Out-Null
        $azuredatatable.columns.add("RuleID",[String]) | Out-Null
        $azuredatatable.columns.add("Title",[String]) | Out-Null
        $azuredatatable.columns.add("Impact",[String]) | Out-Null
        $azuredatatable.columns.add("Recommendation",[String]) | Out-Null
        $azuredatatable.columns.add("MoreInfo",[String]) | Out-Null
        $azuredatatable.columns.add("ImpactedDatabasename",[String]) | Out-Null
        $azuredatatable.columns.add("ImpactedObjectType",[String]) | Out-Null
        $azuredatatable.columns.add("ImpactDetail",[String]) | Out-Null


        $processStartTime = Get-Date
        $datetime = Get-Date
        $content = Get-Content $_.FullName -Raw

        # when a database assessment fails the assessment recommendations and impacted objects arrays
        # will be blank.  Setting them to default values allows for the errors to be captured
        $blankAssessmentRecommendations =   (New-Object PSObject |
                                           Add-Member -PassThru NoteProperty CompatibilityLevel NA |
                                           Add-Member -PassThru NoteProperty Category NA          |
                                           Add-Member -PassThru NoteProperty Severity NA     |
                                           Add-Member -PassThru NoteProperty ChangeCategory NA |
                                           Add-Member -PassThru NoteProperty RuleId NA |
                                           Add-Member -PassThru NoteProperty Title NA |
                                           Add-Member -PassThru NoteProperty Impact NA |
                                           Add-Member -PassThru NoteProperty Recommendation NA |
                                           Add-Member -PassThru NoteProperty MoreInfo NA |
                                           Add-Member -PassThru NoteProperty ImpactedObjects NA
                                        )

        $blankImpactedObjects = (New-Object PSObject |
                                           Add-Member -PassThru NoteProperty Name NA |
                                           Add-Member -PassThru NoteProperty ObjectType NA          |
                                           Add-Member -PassThru NoteProperty ImpactDetail NA
                                        )

        $blankImpactedDatabases = (New-Object PSObject |
                                           Add-Member -PassThru NoteProperty Name NA |
                                           Add-Member -PassThru NoteProperty ObjectType NA          |
                                           Add-Member -PassThru NoteProperty ImpactDetail NA
                                        )


        # Start looping through each JSON array

        #fill dataset for ReportData table
        foreach($obj in (ConvertFrom-Json $content)) #level 1, the actual file
        {
            foreach($database in $obj.Databases) #level 2, the sources
            {
                $database.AssessmentRecommendations = if($database.AssessmentRecommendations.Length -eq 0) {$blankAssessmentRecommendations } else {$database.AssessmentRecommendations}

                foreach($assessment in $database.AssessmentRecommendations) #level 3, the assessment
                {

                    $assessment.ImpactedObjects = if ($assessment.ImpactedObjects.Length -eq 0) {$blankImpactedObjects} else {$assessment.ImpactedObjects}

                    foreach($impactedobj in $assessment.ImpactedObjects) #level 4, the impacted objects
                    {

                        #TODO Get date here will eventually be replace with timestamp from JSON file
                        $datatable.rows.add((Get-Date).toString(), $database.ServerName, $database.Status, $database.Name, $database.SizeMB, $database.CompatibilityLevel, $assessment.CompatibilityLevel, $assessment.Category, $assessment.severity, $assessment.ChangeCategory, $assessment.RuleId, $assessment.Title, $assessment.Impact, $assessment.Recommendation, $assessment.MoreInfo, $impactedobj.Name, $impactedobj.ObjectType, $impactedobj.ImpactDetail, $null, $obj.TargetPlatform, $obj.Name) | Out-Null
                    }
                }
            }
        }

        #fill data set for AzureFeatureParity table
        foreach($obj in (ConvertFrom-Json $content)) #level 1, the actual file
        {
            foreach($serverInstances in $obj.ServerInstances) #level 2, the ServerInstances
            {
                foreach($assessment in $serverInstances.AssessmentRecommendations) #level 3, the assessment
                {
                    $impactedDatabases = if (($assessment.ImpactedDatabases -eq $null) -or ($assessment.ImpactedDatabases.Length -eq 0)) {$blankImpactedDatabases} else {$assessment.ImpactedDatabases}
  
                    foreach($impacteddbs in $impactedDatabases) #level 4, the impacted objects
                    { 
                        #TODO Get date here will eventually be replace with timestamp from JSON file
                        $azuredatatable.rows.add((Get-Date).toString(), $serverInstances.ServerName, $serverInstances.Version, $serverInstances.Status, $assessment.Category, $assessment.Severity, $assessment.FeatureParityCategory, $assessment.RuleId, $assessment.Title, $assessment.Impact, $assessment.Recommendation, $assessment.MoreInfo, $impacteddbs.Name, $impacteddbs.ObjectType, $impacteddbs.ImpactDetail) | Out-Null
                    }
  
                }
            }
        }

        $rowcount_rd = $datatable.rows.Count
        $rowcount_afp = $azuredatatable.rows.Count

        $query1='dbo.JSONResults_Insert'
        $query2='dbo.AzureFeatureParityResults_Insert'

        #Connect
        $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $conn.Open() | Out-Null

        $cmd1 = New-Object System.Data.SqlClient.SqlCommand
        $cmd1.Connection = $conn
        $cmd1.CommandType = [System.Data.CommandType]"StoredProcedure"
        $cmd1.CommandText= $query1
        $cmd1.Parameters.Add("@JSONResults" , [System.Data.SqlDbType]::Structured) | Out-Null
        $cmd1.Parameters["@JSONResults"].Value =$datatable

        $cmd2 = New-Object System.Data.SqlClient.SqlCommand
        $cmd2.Connection = $conn
        $cmd2.CommandType = [System.Data.CommandType]"StoredProcedure"
        $cmd2.CommandText= $query2
        $cmd2.Parameters.Add("@AzureFeatureParityResults" , [System.Data.SqlDbType]::Structured) | Out-Null
        $cmd2.Parameters["@AzureFeatureParityResults"].Value = $azuredatatable

        $ds1=New-Object system.Data.DataSet
        $da1=New-Object system.Data.SqlClient.SqlDataAdapter($cmd1)

        $ds2=New-Object system.Data.DataSet
        $da2=New-Object system.Data.SqlClient.SqlDataAdapter($cmd2)

        # ensure that the dataset can write to the database, if not the dont move the file to processed directory
        try
        {
            $da1.fill($ds1) | Out-Null
            $da2.fill($ds2) | out-null

            try
            {
                Move-Item $filename $processedDir -Force
            }
            catch
            {
                write-host("Error moving file $filename to directory") -ForegroundColor Red
                $error[0]|format-list -force
            }

        }
        catch
        {
            $rowcount_rd = 0
            $rowcount_afp = 0
            write-host("Error writing results for file $filename to database") -ForegroundColor Red
            $error[0]|format-list -force
        }

        $conn.Close()

        $processEndTime = Get-Date
        $processTime = NEW-TIMESPAN -Start $processStartTime -End $processEndTime
        Write-Host("Rows Processed for ReportData Table = $rowcount_rd  Rows processed for AzureFeatureParityTable = $rowcount_afp for file $filename Total Processing Time = $processTime")

        $datatable.Clear()
        $azuredatatable.Clear()

    }
}

#------------------------------------------------------------------------------------  END FUNCTIONS ------------------------------------------------------------------------------------------





#------------------------------------------------------------------------------------- EXECUTE FUNCTIONS --------------------------------------------------------------------------------------

dmaProcessor -serverName localhost `
            -databaseName DMAReporting `
            -jsonDirectory "C:\DMAResults\" `
            -processTo SQLServer



#        To process on a named instance use SERVERNAME\INSTANCENAME as the -serverName

#------------------------------------------------------------------------------------ END EXECUTE FUNCTIONS ------------------------------------------------------------------------------------

