using namespace Microsoft.Azure.Commands.Sql.DataSync.Model
using namespace System.Collections.Generic
param (
[Parameter(Mandatory=$true)][string]$SubscriptionId = "",
[Parameter(Mandatory=$true)][string]$ResourceGroupName = "",
[Parameter(Mandatory=$true)][string]$ServerName = "",
[Parameter(Mandatory=$true)][string]$DatabaseName = "",
[Parameter(Mandatory=$true)][string]$SyncGroupName = "",
[string]$MemberName = "",
[int]$TimeoutInSeconds = 900,
[switch]$RefreshDatabaseSchema = $false,
[switch]$AddAllTables = $false,
[string]$TablesAndColumnsToAdd = "",
[string]$TablesAndColumnsToRemove = "")

$TablesAndColumnsToAddList = [System.Collections.ArrayList]::new($TablesAndColumnsToAdd.Split(","))
$TablesAndColumnsToRemoveList = [System.Collections.ArrayList]::new($TablesAndColumnsToRemove.Split(","))
$TempFile = $env:TEMP+"\syncSchema.json"

##login to Azure account
login-azurermaccount

##select the subscription
select-azurermsubscription -SubscriptionId $SubscriptionId

##get sync group and check if sync group exists
$SyncGroup = Get-AzureRmSqlSyncGroup -ResourceGroupName $ResourceGroupName `
                                     -ServerName $ServerName `
                                     -DatabaseName $DatabaseName `
                                     -Name $SyncGroupName

if ($SyncGroup -eq $null)
{
    Write-Host "Sync group $SyncGroupName is not found."
    exit;
}

##if member name specified, check if member exists
if ($MemberName -ne "")
{
    $SyncMember = Get-AzureRmSqlSyncMember -ResourceGroupName $ResourceGroupName `
                                           -ServerName $ServerName `
                                           -DatabaseName $DatabaseName `
                                           -SyncGroupName $SyncGroupName `
                                           -Name $MemberName
    if ($SyncMember -eq $null)
    {
        Write-Error "Sync member $MemberName is not found."
        exit;
    }
}


## Refresh database schema if -RefreshDatabaseSchema is specified
$DatabaseSchema = ""
if ($RefreshDatabaseSchema)
{
    $StartTime = Get-Date
    if ($MemberName -eq "")
    {
        Write-Host "Refreshing database schema from hub database"
        Update-AzureRmSqlSyncSchema -ResourceGroupName $ResourceGroupName `
                                    -ServerName $ServerName `
                                    -DatabaseName $DatabaseName `
                                    -SyncGroupName $SyncGroupName
    }
    else
    {
        Write-Host "Refreshing database schema from member $MemberName"
        Update-AzureRmSqlSyncSchema -ResourceGroupName $ResourceGroupName `
                                    -ServerName $ServerName `
                                    -DatabaseName $DatabaseName `
                                    -SyncGroupName $SyncGroupName `
                                    -SyncMemberName $MemberName
    }

    ## Wait until the database schema is refreshed
    $TimeoutTimeSpan = New-TimeSpan -Start $StartTime -End $StartTime
    $IsSucceeded = $false
    While ($TimeoutTimeSpan.TotalSeconds -le $TimeoutInSeconds)
    {
        Start-Sleep -s 10

        if ($MemberName -eq "")
        {
            $DatabaseSchema = Get-AzureRmSqlSyncSchema -SyncGroupName $SyncGroupName `
                                                       -ServerName $ServerName `
                                                       -DatabaseName $DatabaseName `
                                                       -ResourceGroupName $ResourceGroupName
        }
        else
        {
            $DatabaseSchema = Get-AzureRmSqlSyncSchema -SyncGroupName $SyncGroupName `
                                                       -ServerName $ServerName `
                                                       -DatabaseName $DatabaseName `
                                                       -ResourceGroupName $ResourceGroupName `
                                                       -SyncMemberName $MemberName
        }

        if ($DatabaseSchema.LastUpdateTime -gt $StartTime.ToUniversalTime())
        {
            Write-Host "Database schema succeeded"
            $IsSucceeded = $true
            break;
        }
    }

    if (-not $IsSucceeded)
    {
        Write-Error "Refresh failed or timeout"
        exit;
    }
}
else
{
    if ($MemberName -eq "")
    {
        $DatabaseSchema = Get-AzureRmSqlSyncSchema -SyncGroupName $SyncGroupName `
                                                   -ServerName $ServerName `
                                                   -DatabaseName $DatabaseName `
                                                   -ResourceGroupName $ResourceGroupName
    }
    else
    {
        $DatabaseSchema = Get-AzureRmSqlSyncSchema -SyncGroupName $SyncGroupName `
                                                   -ServerName $ServerName `
                                                   -DatabaseName $DatabaseName `
                                                   -ResourceGroupName $ResourceGroupName `
                                                   -SyncMemberName $MemberName
    }
}

if ($DatabaseSchema.LastUpdateTime -eq $null)
{
    Write-Error "Database schema is not available. Refresh the database schema by specify -RefreshDatabaseSchema"
    Exit;
}

## Remove specified tables and columns from sync schema
## Also remove tables and columns which is not defined in the database if database schema is refreshed
$TablesToRemove = New-Object "System.Collections.Generic.List[AzureSqlSyncGroupSchemaTableModel]";
foreach ($TableSchema in $SyncGroup.Schema.Tables)
{
    $TableInDatabase = $DatabaseSchema.Tables | ? QuotedName -eq $TableSchema.QuotedName

    if ($TablesAndColumnsToRemoveList.Contains($TableSchema.QuotedName) -or $TableInDatabase -eq $null)
    {
        $TablesToRemove.Add($TableSchema);
    }
    else
    {
        $ColumnsToRemove = New-Object "System.Collections.Generic.List[AzureSqlSyncGroupSchemaColumnModel]";
        foreach($ColumnSchema in $TableSchema.Columns)
        {
            $ColumnInTable = $TableInDatabase[0].Columns | ? QuotedName -eq $ColumnSchema.QuotedName
            $FullName = $TableSchema.QuotedName+"."+$ColumnSchema.QuotedName
            if ($TablesAndColumnsToRemoveList.Contains($FullName) -or $ColumnInTable -eq $null)
            {
                $ColumnsToRemove.Add($ColumnSchema);
            }
        }

        if ($ColumnsToRemove.Count -gt 0)
        {
            foreach ($ColumnToRemove in $ColumnsToRemove)
            {
                $FullName = $TableSchema.QuotedName+"."+$ColumnToRemove.QuotedName
                Write-Host "$FullName is being removed from sync schema"
                $TableSchema.Columns.Remove($ColumnToRemove);
            }
        }
    }
}

if ($TablesToRemove.Count -gt 0)
{
    foreach ($TableToRemove in $TablesToRemove)
    {
        Write-Host $TableToRemove.QuotedName" is being removed from sync schema"
        $SyncGroup.Schema.Tables.Remove($TableToRemove);
    }
}

## Add specified tables and columns to the sync schema
foreach ($TableSchema in $DatabaseSchema.Tables)
{
    ## Reuse if the table already exists in the schema; Otherwise, create a new one
    $newTableSchema = $SyncGroup.Schema.Tables | ? QuotedName -eq $TableSchema.QuotedName
    $AddNewTable = $false
    if ($newTableSchema -eq $null)
    {
        $AddNewTable = $true
        $newTableSchema = [AzureSqlSyncGroupSchemaTableModel]::new()
        $newTableSchema.QuotedName = $TableSchema.QuotedName
        $newTableSchema.Columns = [List[AzureSqlSyncGroupSchemaColumnModel]]::new();
    }

    ## If the table name is specified, add all valid columns
    $addAllColumns = $false
    if ($AddAllTables -or $TablesAndColumnsToAddList.Contains($TableSchema.QuotedName))
    {
        ## If the table is not supported, move to next table
        if ($TableSchema.HasError)
        {
            $fullTableName = $TableSchema.QuotedName
            Write-Host "Can't add table $fullTableName to the sync schema" -foregroundcolor "Red"
            Write-Host $TableSchema.ErrorId -foregroundcolor "Red"
            continue;
        }
        else
        {
            $addAllColumns = $true
        }
    }

    ## Add columns
    foreach($columnSchema in $TableSchema.Columns)
    {
        $fullColumnName = $TableSchema.QuotedName + "." + $columnSchema.QuotedName
        if ($addAllColumns -or $TablesAndColumnsToAddList.Contains($fullColumnName))
        {
            ## If the column already exists in the sync schema or not supported, ignore
            $Column = $newTableSchema.Columns | ? QuotedName -eq $columnSchema.QuotedName
            if ($Column -ne $null)
            {
                Write-Host "Column $fullColumnName is already in the schema"
            }
            elseif ((-not $addAllColumns) -and $TableSchema.HasError)
            {
                Write-Host "Can't add column $fullColumnName to the sync schema" -foregroundcolor "Red"
                Write-Host $tableSchema.ErrorId -foregroundcolor "Red"
            }
            elseif ((-not $addAllColumns) -and $columnSchema.HasError)
            {
                Write-Host "Can't add column $fullColumnName to the sync schema" -foregroundcolor "Red"
                Write-Host $columnSchema.ErrorId -foregroundcolor "Red"
            }
            else
            {
                Write-Host "Adding $fullColumnName to the sync schema"
                $newColumnSchema = [AzureSqlSyncGroupSchemaColumnModel]::new()
                $newColumnSchema.QuotedName = $columnSchema.QuotedName
                $newColumnSchema.DataSize = $columnSchema.DataSize
                $newColumnSchema.DataType = $columnSchema.DataType
                $newTableSchema.Columns.Add($newColumnSchema)
            }
        }
    }
    if ($newTableSchema.Columns.Count -gt 0 -and $AddNewTable)
    {
        $SyncGroup.Schema.Tables.Add($newTableSchema)
    }
}

## Update the master sync member name if database metadata is from the member
if ($MemberName -ne "")
{
    $SyncGroup.Schema.MasterSyncMemberName = $MemberName
}
else
{
    $SyncGroup.Schema.MasterSyncMemberName = $null
}

$schemaString = $SyncGroup.Schema | ConvertTo-Json -depth 5 -Compress

# workaround a powershell bug if the PowerShell version is too early
$schemaString = $schemaString.Replace('"Tables"', '"tables"').Replace('"Columns"', '"columns"').Replace('"QuotedName"', '"quotedName"').Replace('"MasterSyncMemberName"','"masterSyncMemberName"')

Write-Host "Write the schema to $TempFile"
$schemaString | Out-File $TempFile

# Update the sync schema
Update-AzureRmSqlSyncGroup -ResourceGroupName $ResourceGroupName `
                           -ServerName $ServerName `
                           -DatabaseName $DatabaseName `
                           -Name $SyncGroupName `
                           -SchemaFile $TempFile