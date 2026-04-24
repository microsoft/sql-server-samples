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
# ----------------------------------------------------------------------------------
#
# Powershell script for loading telemetry data from elastic pools and elastic database
# into a telemetry database. To be used in conjunction with PoolTelemetry.ps1, which
# should be installed in the same directory.
#
# This script should be customized as required (see <<<) to select one or more source
# servers, and will then spawn a telemetry gathering job for each server based on
# Load-PoolTelemetryForServer in PoolTelemetry.ps1, which loads telemetry for all
# pools and elastic databases on the server.  Each spawned job will run for an
# extended period in the background, waking up periodically to load more telemetry.
# The interval between telemetry gathering and the total duration can be controlled
# by parameters set in this script.
#
# Pool telemetry is loaded from the server master database, database telemetry is
# optionally loaded from each elastic database. This script assumes a common
# user name and password is used to connect to all source servers and databases.
#
#------------------------------------------------------------------------------
#
## Prompt for Azure login
Login-AzureRMAccount

# Set the Azure subscription, needed if your Microsoft account is associated with multiple subscriptions  <<< ***
$AzureSubscriptionName = '<Your Subscription Name>'
$Subscription = Get-AzureRmSubscription -SubscriptionName $AzureSubscriptionName | Select-AzureRmSubscription

$SubscriptionId = $Subscription.Subscription.SubscriptionId

## Get SQL Server credentials.  NOTE: same credential assumed for all source servers <<< ***
$sourceCred = Get-Credential -Message 'User name and password for source server' -UserName  '<source user name>'# add user name here
$outputServerCred = Get-Credential -Message 'User name and password for telemetry database' -UserName  '<telemetry user name>'# add user name here

## Resource group and server used for source server selection  <<< ***
$resourceGroupName = '<resource group name>' # name of resource group containing the server from which telemetry will be gathered - see https://portal.azure.com
$serverName = '<servername>' # name of server from which telemetry will be gathered - e.g. "myappserver"

## Telemetry database server and database name <<< ***
$outputServerName = '<telemetry server name>' # server name of telemetry database, like "telemetryserver"
$outputDatabaseName = '<telemetry database name>' # telemetry database name, like "ElasticPoolTelemetry"

## Set server list checking    <<< ***
$staticServerList = $false  # set to $true if server list will not change during telemetry gathering period

## Set telemetry collection timing <<< ***
$intervalMinutes = 15 # interval between telemetry collections used by spawned server job (15-30 mins suggested)
$durationMinutes = 60 # total duration for collection of telemetry and checking servers; 0 for one time execution, or a multiple of the interval.

## Set to $true to include all available pool telemetry (up to 14 days). Be careful if rerunning on the same server as this may load duplicate data <<< ***
$loadAllAvailablePoolTelemetry = $false

## Set to $true to gather 15 sec telemetry for elastic databases. Caution: large volumes of data may be returned. <<< ***
[bool]$includeDatabases = $false # or $False

$now = [DateTime]::UtcNow
[DateTime]$startTime = $now # sets the start time for the first telemetry collection
[DateTime]$finishTime = $now.AddMinutes($DurationMinutes) # sets the overall finish time for a telemetry collection session

Write-Host "Starting telemetry gathering for period" $startTime "to" $finishTime

# Initialize the jobs list
$jobs = @{}

# Check for the server(s) from which to gather telemetry.  As servers may be added or removed during the telemetry gathering
# period the server list is re-evaluated periodically

# The following identifies the servers to be analyzed and starts a job for each server to gather telemetry data
# In each iteration the latest server list is compared to the running jobs list and additional jobs started or
# current jobs stopped as required.

while ($startTime -le $finishTime)
{
    Write-Host "Finding servers as at" $startTime "(UTC)"

    # initialize the servers list for each iteration
    $servers = [ordered]@{}

    # Use or adapt one of the following queries as needed to select the source servers from which to load telemetry. <<< ***

    ## Get a specific server
    #$server = Get-AzureRmSqlServer -ResourceGroupName $resourceGroupName -ServerName $serverName
    #$servers.Add($server.ServerName, $server)

    ## Get all servers in a specific resource group
    #$servers = Get-AzureRmSqlServer -ResourceGroupName $resourceGroupName

    ## Get all resources of type server in the subscription
    #$resourceList = Find-AzureRmResource -ResourceType microsoft.sql/servers

    ## Get all resources of type server in a specific region
    $resourceList = Find-AzureRmResource -ResourceType microsoft.sql/servers -ODataQuery "(Location eq 'australiasoutheast' or Location eq 'australiaeast')"

    ## Get all resources of type server with common name pattern
    #$resourceList = Find-AzureRmResource -ResourceType Microsoft.Sql/servers -ResourceNameContains '<common text>'

    # If selecting resources by populating $resourceList populate an equivalent $servers list
    foreach ($resource in $resourceList)
    {
        $server = Get-AzureRmSqlServer -ResourceGroupName $resource.ResourceGroupName -ServerName $resource.Name
        $servers.Add($server.ServerName, $server)
    }

    Write-Host $servers.Count "servers found"

    $scriptPath = "$PSScriptRoot\PoolTelemetry.ps1"
    $initScript = (Get-Command $scriptPath).ScriptBlock

    # For each server, start a job to collect telemetry.  Set job name to the server name and put the job in $jobs
    foreach($server in $servers.Values)
    {
        if ($jobs.Contains($server.ServerName) -eq $false)
        {
            $job = Start-Job -Name $server.ServerName -ScriptBlock {
                    param ($sp, $all, $inc, $sub, $rgn, $sn, $loc, $sc, $osn, $odn, $osc, $im, $dm)
                    . $sp
                    Load-PoolTelemetryForServer -loadAllAvailablePoolTelemetry $all -IncludeDatabases $inc `
                        -SubscriptionId $sub -ResourceGroupName $rgn -ServerName $sn -Location $loc -ServerCred $sc -OutputServerName $osn -OutputDatabaseName $odn -OutputServerCred $osc -IntervalMinutes $im -DurationMinutes $dm} `
                -ArgumentList $scriptPath, $loadAllAvailablePoolTelemetry, $includeDatabases, $SubscriptionId,  $server.ResourceGroupName, $server.ServerName, $server.Location, $sourceCred, $outputServerName, $outputDatabaseName, $outputServerCred, $intervalMinutes, $durationMinutes

            $jobs.Add($server.ServerName, $job)

            Write-Host "Job started for server" $server.ServerName

            # Following is useful for debugging changes to PoolTelemetry.ps1.  Best used with a single server unless you set the duration to 0
            #. $scriptPath
            #Load-PoolTelemetryForServer -loadAllAvailablePoolTelemetry $loadAllAvailablePoolTelemetry -IncludeDatabases $IncludeDatabases -SubscriptionId $SubscriptionId -ResourceGroupName $server.ResourceGroupName `
            #    -ServerName $server.ServerName -Location $server.Location -ServerCred $sourceCred -OutputServerName $outputServerName `
            #    -OutputDatabaseName $outputDatabaseName -OutputServerCred $outputServerCred -IntervalMinutes $intervalMinutes -DurationMinutes $durationMinutes
        }
    }

    # if server list doesn't change then no need to re-evaluate server list or manage the jobs. Already spawned jobs will continue to run.
    if ($staticServerList) {break}

    # Stop previously started jobs if the server has been deleted
    # For each started job in $jobs, check if the server is still in the most recent server list; if not, stop the job
    foreach($job in $jobs.Values)
    {
        if ($servers.Contains($job.Name) -eq $false)
        {
            Write-Host "Server" $server.ServerName "no longer exists.  Stopping its telemetry gathering job"

            Stop-Job $job.Name

            # Remove-Job
            # leaving above commented-out allows use of Receive-Job to inspect the trace info emitted by the job
        }
    }

    # set up start time for next evaluation of the server list
    $startTime = $startTime.AddMinutes($intervalMinutes)

    # sleep until next start time to ensure telemetry continues to be gathered
    Write-Host "Sleeping until" $startTime "(UTC)"

    do
    {
        Start-Sleep 1

    } until (([DateTime]::UtcNow) -ge $startTime)
}

# For a static server list this runner script terminates after one pass and the jobs are left running
# Otherwise the jobs are stopped as they will at this point have concluded telemetry collection.
# In both cases Job trace output can be inspected with Receive-Job unless the jobs are removed.
# use Get-Job and Receive-Job [n] -Keep where n is the job number to see the output.

if (-not $staticServerList)
{
    # gathering period is complete, now stop all the jobs

    Write-Host "Session complete, stopping all jobs"

    Stop-Job *

    #Remove-Job *
    # leaving above commented-out allows use of Receive-Job to inspect the trace info emitted by the job

    get-job
}

