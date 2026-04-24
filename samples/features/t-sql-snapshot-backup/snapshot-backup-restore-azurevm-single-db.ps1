$subscriptionId ='########-####-####-####-############'
$subscriptionName = 'YOUR-AZURE-SUBSCRIPTION-NAME'
$resourceGroupName = 'YOUR-AZURE-RESOURCE-GROUP-NAME'
$location = 'YOUR-AZURE-RESOURCE-GROUP-LOCATION'
$vmName = 'YOUR-VIRTUAL-MACHINE-NAME'
$snapshotName = 'SNAPSHOT-NAME'
$diskName = "YOUR-SNAPSHOT-BACKUP-NAME"
$storageType = '' # E.g., 'Premium_LRS'
$bkmFile = "FILEPATH-FOR-THE-.BKM-FILE" # E.g., "C:\BKP\db.bkm"

$SQLServer = "YOUR-SQL-SERVER-INSTANCE-NAME"
$db = "YOUR-DATABASE-NAME"

$suspendDb = "ALTER DATABASE [" + $db +"] SET SUSPEND_FOR_SNAPSHOT_BACKUP=ON;"
$backupMetadata = "BACKUP DATABASE [" + $db +"] TO DISK='" + $bkmfile + "' WITH METADATA_ONLY, FORMAT;"
$unsuspendDb = "ALTER DATABASE [" + $db + "] SET SUSPEND_FOR_SNAPSHOT_BACKUP=OFF;"

$createDB="IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = '" + $db + "') CREATE DATABASE " + $db
$dropDB="IF EXISTS(SELECT * FROM sys.databases WHERE name = '" + $db + "') BEGIN ALTER DATABASE [" + $db +"] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE " + $db + " END"
$mdfFile = "F:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\" + $db +".mdf"
$ldfFile = "F:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\" + $db +"_log.ldf"

$restoreDB = "RESTORE DATABASE [" + $db +"] FROM DISK='" + $bkmFile + "' WITH METADATA_ONLY, MOVE '" + $db +"' TO '" + $mdfFile + "', MOVE '" + $db +"_log' TO '" + $ldfFile + "';"


# Login and set the Azure subscription
###########################################
az login
Connect-AzAccount
Select-AzSubscription -SubscriptionId $subscriptionId
az account set --subscription $subscriptionName

# Import Modules
###########################################
Import-Module -Name SQLPS
Install-Module -Name Az

# Create a sample database
###########################################
$sqlConn = New-Object System.Data.SQLClient.SQLConnection
# Open SQL Server connection to master
$sqlConn.ConnectionString = "server='" + $SQLServer +"';database='master';Integrated Security=True;"
$sqlConn.Open()

    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $sqlConn

    # Create Database
    $Command.CommandText = $createDB
    $Result = $Command.ExecuteNonQuery();

# Close SQL Server connection
$sqlConn.Close()

# Take a snapshot backup
###########################################

$sqlConn.ConnectionString = "server='" + $SQLServer +"';database='" + $db +"';Integrated Security=True;"

# Open SQL Server connection
$sqlConn.Open()

    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $sqlConn

    # Suspend Database
    $Command.CommandText = $suspendDb
    $Result = $Command.ExecuteNonQuery();

    # Take a disk snapshot
    try
    {
        $osDiskId=az vm show -g $resourceGroupName -n $vmName --query "storageProfile.osDisk.managedDisk.id" -o tsv
        az snapshot create -g $resourceGroupName --source "$osDiskId" --name $snapshotName
    }
    catch
    {
        # Unsuspend Database
        $Command.CommandText = $unsuspendDb
        $Result = $Command.ExecuteNonQuery();
    }

    # Backup database metadata
    $Command.CommandText = $backupMetadata
    $Result = $Command.ExecuteNonQuery();

    # Unsuspend Database
    $Command.CommandText = $unsuspendDb
    $Result = $Command.ExecuteNonQuery();

# Close SQL Server connection
$sqlConn.Close()

# Mount Disk
###########################################

$snapshot = Get-AzSnapshot -SnapshotName $snapshotName

# Create Disk from snapshot
$diskConfig = New-AzDiskConfig -AccountType $storageType -Location $location -CreateOption Copy -SourceResourceId $snapshot.Id -Zone 1
New-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName -Disk $diskConfig

#Attach disk to VM
$disk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName
$vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroupName

$vm = Add-AzVMDataDisk -Name $diskName -CreateOption Attach -Lun 0 -VM $vm -ManagedDiskId $disk.Id
Update-AzVM -VM $vm -ResourceGroupName $resourceGroupName

# Bring disk online
###########################################
# TODO: Get Disk Number programmatically - Currently hardcoded to 2
Set-Disk -Number 2 -IsOffline $false


# Drop database and restore from snapshot
###########################################
# Open SQL Server connection to master
$sqlConn.ConnectionString = "server='" + $SQLServer +"';database='master';Integrated Security=True;"
$sqlConn.Open()

    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $sqlConn

    # Drop Database
    $Command.CommandText = $dropDB
    $Result = $Command.ExecuteNonQuery();

    # Restore Database
    $Command.CommandText = $restoreDB
    $Result = $Command.ExecuteNonQuery();

# Close SQL Server connection
$sqlConn.Close()


# Clean up
###########################################

# Open SQL Server connection to master
$sqlConn.ConnectionString = "server='" + $SQLServer +"';database='master';Integrated Security=True;"
$sqlConn.Open()

    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $sqlConn

    # Drop Database
    $Command.CommandText = $dropDB
    $Result = $Command.ExecuteNonQuery();

# Close SQL Server connection
$sqlConn.Close()


# Remove snapshot
Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Force;

# Remove metadata file
if (Test-Path $bkmFile) {
  Remove-Item $bkmFile
}

# Remove disk from VM
$vm = Remove-AzVMDataDisk -VM $vm -Name $diskName
Update-AzVM -VM $vm -ResourceGroupName $resourceGroupName

# Remove unmanaged disk
Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName -Force;
