# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ---------------------------------------------------------------------------------
#
#  Sample script for loading SQL Database telemetry for pools and elastic databases
#  on a single server into a user-supplied Azure SQL database.  Script will populate
#  the target schema if not present.
#
#
#  See additional comments in PoolTelemetryRunner.ps1, which includes instructions for
#  running this script as a PowerShell job, enabling data gathering for large numbers
#  of servers in the background.
#
#
function Load-PoolTelemetryForServer {
    param (
    [Parameter(Mandatory=$true)][string]$SubscriptionId, # Azure subscription owning the server from which telemetry will be gathered - see https://portal.azure.com
    [Parameter(Mandatory=$true)][string]$ResourceGroupName, # name of resource group containing the server from which telemetry will be gathered - see https://portal.azure.com
    [Parameter(Mandatory=$true)][string]$ServerName, # name of server from which telemetry will be gathered - e.g. "myappserver"
    [Parameter(Mandatory=$true)][string]$Location, # location of server, e.g. "Australia Southeast"
    [Parameter(Mandatory=$true)][PSCredential]$ServerCred,
    [Parameter(Mandatory=$true)][string]$OutputServerName, # server name of telemetry database, like "telemetryserver"
    [Parameter(Mandatory=$true)][string]$OutputDatabaseName, # telemetry database name, like "telemetrydb"
    [Parameter(Mandatory=$true)][PSCredential]$OutputServerCred,
    [Parameter(Mandatory=$true)][int]$IntervalMinutes, # interval for collection of telemetry
    [Parameter(Mandatory=$true)][int]$DurationMinutes, # total duration for collection of telemetry
    [Parameter(Mandatory=$true)][bool]$loadAllAvailablePoolTelemetry, # indicates if all available telemetry should be loaded on th first pass
    [Parameter(Mandatory=$true)][bool]$IncludeDatabases # indicates if telemetry should be gathered for databases as well as pools
    )

    # Create output database metrics collection tables if it does not already exist.

    $OutputServerCred.Password.MakeReadOnly()
    $sqlCred = new-object ("System.Data.SqlClient.SqlCredential") -ArgumentList $OutputServerCred.UserName, $OutputServerCred.Password

    $outputConnection = New-Object ("System.Data.SqlClient.SqlConnection") "Data Source=$OutputServerName.database.windows.net;Integrated Security=false;Initial Catalog=$OutputDatabaseName"
    $outputConnection.Credential = $sqlCred
    $outputConnection.Open()

    $poolResourceStatsTable = "pool_resource_stats"  # <<< update if a different table name is required
    $dbResourceStatsTable = "db_resource_stats"      # <<< update if a different table name is required

    $sql =`
    "-- Create table for holding collected pool resource stats
    IF  NOT EXISTS (SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'$($poolResourceStatsTable)') AND type in (N'U'))

    BEGIN
    Create Table $($poolResourceStatsTable) (subscription_guid uniqueidentifier, resource_group_name varchar(128), server_name varchar(128), location varchar(128), elastic_pool_name varchar(128), end_time datetime,
    elastic_pool_DTU_limit int, avg_cpu_percent decimal(5,2), avg_data_io_percent decimal(5,2), avg_log_io_percent decimal(5,2), max_worker_percent decimal(5,2), max_session_percent decimal(5,2)
    , avg_DTU_percent decimal(5,2), avg_storage_percent decimal(5,2), elastic_pool_storage_limit_mb bigint);
    Create Clustered Index ci_endtime ON $($poolResourceStatsTable) (end_time);
    END

    -- Create table for holding collected database resource stats
    IF  NOT EXISTS (SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'$($dbResourceStatsTable)') AND type in (N'U'))

    BEGIN
    Create Table $($dbResourceStatsTable) (subscription_guid uniqueidentifier, resource_group_name varchar(128),server_name varchar(128), location varchar(128), elastic_pool_name varchar(128), database_name varchar(128), end_time datetime,
    database_DTU_limit int, avg_cpu_percent decimal(5,2), avg_data_io_percent decimal(5,2), avg_log_io_percent decimal(5,2), max_worker_percent decimal(5,2), max_session_percent decimal(5,2), avg_DTU_percent decimal(5,2), db_size float);
    Create Clustered Index ci_endtime ON $($dbResourceStatsTable) (end_time);
    END

    -- Create a function to get aggregated metrics for a given time interval
    IF  NOT EXISTS (SELECT * FROM sys.objects
    WHERE name = N'get_aggregated_pool_metrics' AND type in ('IF'))
    EXEC sp_executesql @Statement = N'
		Create function get_aggregated_pool_metrics(
		@start datetime
		,@end datetime)
		RETURNS TABLE
		AS
		RETURN
		(
			SELECT
				location, server_name, elastic_pool_name
				,avg([avg_dtu_percent]) as avg_eDTU_percent
				,avg([avg_cpu_percent]) as avg_cpu_percent
				,avg([avg_data_io_percent]) as avg_data_io_percent
				,avg([avg_log_io_percent]) as avg_log_io_percent
				,avg([avg_storage_percent]) as avg_storage_percent
				,max([avg_dtu_percent]) as max_of_avg_eDTU_percent
				,max([avg_cpu_percent]) as max_of_avg_cpu_percent
				,max([avg_data_io_percent]) as max_of_data_io_percent
				,max([avg_log_io_percent]) as max_of_avg_log_io_percent
				,max([avg_storage_percent]) as max_of_avg_storage_percent
				,max([max_worker_percent]) as max_workers_percent
				,max([max_session_percent]) as max_session_percent
			FROM [dbo].[pool_resource_stats]
			WHERE end_time between @start and @end
			group by location, server_name, elastic_pool_name
		)'
    "


    $outputServerFullname = $OutputServerName + '.database.windows.net' # assumes server is in Azure SQL Database

    Invoke-Sqlcmd -ServerInstance $outputServerFullName -Database $OutputDatabaseName -Username $OutputServerCred.UserName -Password $OutputServerCred.GetNetworkCredential().Password -Query $sql -ConnectionTimeout 120 -QueryTimeout 120

    $sourceServerFullName = $ServerName + '.database.windows.net'

    $interval = $IntervalMinutes
    $now = [DateTime]::UtcNow
    [DateTime]$startTime = $now.AddMinutes(-$interval) # sets the start time for the first telemetry collection
    [DateTime]$endTime = $now # sets the end time
    [DateTime]$finishTime = $now.AddMinutes($DurationMinutes) # sets the overall finish time for a telemetry collection session

    Write-Host "Starting to collect telemetry for" $ServerName

    $poolLagMinutes = 30  # This accommodates the lag in pool-level metrics being available in the DMV, does not affect per database telemetry

    while($startTime -lt $finishTime)
    {
        if ($loadAllAvailablePoolTelemetry)
        {
            $poolStartTime = $startTime.AddMinutes(-21600) # looks back 15 days to ensure gets all available older data
            $loadAllAvailablePoolTelemetry = $false  # switches flag so this is done once only in the loop
        }
        else
        {
            $poolStartTime = $startTime.AddMinutes(-$poolLagMinutes) # sets the normal start of query window
        }

        $poolEndTime = $endTime.AddMinutes(-$poolLagMinutes) # sets end of query window

        Write-Host "Starting to collect elastic pool telemetry for period" $poolStartTime "to" $poolEndTime "(UTC)"

        # Collect metrics for all elastic pools in this server.
        $sql = `
        "SELECT subscription_guid = CAST ('$($SubscriptionId)' AS uniqueidentifier), resource_group_name = '$($ResourceGroupName)', server_name = '$($ServerName)', location = '$($Location)', elastic_pool_name
        , end_time, elastic_pool_dtu_limit, avg_cpu_percent, avg_data_io_percent, avg_log_write_percent as avg_log_io_percent, max_worker_percent, max_session_percent
        ,(SELECT Max(v) FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS value(v)) AS avg_DTU_percent , avg_storage_percent, elastic_pool_storage_limit_mb FROM sys.elastic_pool_resource_stats
        WHERE end_time > '$($poolStartTime)' and end_time <= '$($poolEndTime)';"

        $poolResult = Invoke-Sqlcmd -ServerInstance $sourceServerFullName -Database "master" -Username $ServerCred.UserName -Password $ServerCred.GetNetworkCredential().Password -Query $sql -ConnectionTimeout 120 -QueryTimeout 3600

        if ($poolResult -ne $null)
        {
            #bulk copy the pool telemetry metrics to output database
            $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $outputConnection
            $bulkCopy.BulkCopyTimeout = 600
            $bulkCopy.DestinationTableName = "$poolResourceStatsTable";
            $bulkCopy.WriteToServer($poolResult);

            Write-Host "Elastic pool telemetry loaded for server" $ServerName
        }
        else
        {
            Write-Host "No elastic pool telemetry found for server" $ServerName "for period" $poolStartTime "to" $poolEndTime "(UTC)"
        }

        # gather elastic database telemetry if requested
        if ($IncludeDatabases)
        {
            # Get the list of current elastic databases
            $sql =`
            "select Name, elastic_pool_name from sys.databases as db
            inner join sys.database_service_objectives as dbso on db.database_id = dbso.database_id
            where (dbso.service_objective = 'ElasticPool') and db.Name != 'master'"

            $dbList = Invoke-Sqlcmd -ServerInstance $sourceServerFullName -Database "master" -Username $ServerCred.UserName -Password $ServerCred.GetNetworkCredential().Password -Query $sql -ConnectionTimeout 120 -QueryTimeout 3600

            if ($dbList -ne $null)
            {
                Write-Host $dbList.Count "elastic databases found on server" $ServerName

                # Collect telemetry for each elastic database
                foreach ($db in $dbList)
                {
                    $sql= `
                    "Declare @db_size float;
                    SELECT @db_size = SUM(reserved_page_count) * 8.0/1024/1024 FROM sys.dm_db_partition_stats
                    SELECT subscription_guid = CAST ('$($SubscriptionId)' AS uniqueidentifier), resource_group_name = '$($ResourceGroupName)',server_name = '$($ServerName)', location = '$($Location)', elastic_pool_name = '$($db.elastic_pool_name)'
                    , '$($db.Name)' as database_name, end_time, dtu_limit as database_dtu_limit, avg_cpu_percent, avg_data_io_percent, avg_log_write_percent as avg_log_io_percent, max_worker_percent, max_session_percent
                    ,(SELECT Max(v) FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS value(v)) AS avg_DTU_percent ,@db_size as db_size FROM sys.dm_db_resource_stats
                    WHERE end_time > '$($startTime)' and end_time <= '$($endTime)';"

                    $dbResult = Invoke-Sqlcmd -ServerInstance $SourceServerFullName -Database $db.Name -Username $ServerCred.UserName -Password $ServerCred.GetNetworkCredential().Password -Query $sql -ConnectionTimeout 120 -QueryTimeout 3600

                    if ($dbResult -ne $null)
                    {
                        #bulk copy the data to the telemetry database
                        $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $outputConnection
                        $bulkCopy.BulkCopyTimeout = 600
                        $bulkCopy.DestinationTableName = "$dbResourceStatsTable";
                        $bulkCopy.WriteToServer($dbResult);

                        Write-Host "Telemetry loaded for elastic database" $db.Name
                    }
                    else
                    {
                        Write-Host "No telemetry found for elastic database " $db.Name "for period" $startTime "to" $endTime
                    }
                }
            }
            else
            {
                $now = [DateTime]::UtcNow

                Write-Host "No elastic databases found for" $ServerName "when checking at" $now
            }
        }

        Write-Host "Finished collection for server" $ServerName "for period" $startTime "to" $endTime

        # set up time period for next collection
        $startTime = $startTime.AddMinutes($interval)
        $endTime = $endTime.AddMinutes($interval)

        # end if the next period doesn't start before the finish time
        If ($startTime -ge $finishTime) {break}

        Write-Host "Sleeping until" $endTime "(UTC)"

        do
        {
            Start-Sleep 1
        } until (([DateTime]::UtcNow) -ge $endTime)
    }
}