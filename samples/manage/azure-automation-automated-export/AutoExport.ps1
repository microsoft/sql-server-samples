# The Array that will hold the list of databases objects.
$dbs = New-Object System.Collections.ArrayList;

# The Enums that describe what state a database is in.
Add-Type -TypeDefinition @"
	public enum DatabaseState
	{
		ToCopy,
		Copying,
		ToExport,
		Exporting,
		ToDrop,
		Finished
	}
"@

# The database and server pairs that will be exported.
$databaseServerPairs =
	@([pscustomobject]@{serverName="SAMPLESERVER1";databaseName="SAMPLEDATABASE1"},
	[pscustomobject]@{serverName="SAMPLESERVER1";databaseName="SAMPLEDATABASE2"},
	[pscustomobject]@{serverName="SAMPLESERVER2";databaseName="SAMPLEDATABASE3"}
	);

# The Credentials for the database servers
$serverCred1 = Get-AutomationPSCredential -Name 'NAMEOFSERVERCREDENTIAL1';
$serverCred2 = Get-AutomationPSCredential -Name 'NAMEOFSERVERCREDENTIAL2';
$serverCredentialsDictionary = @{
	'SAMPLESERVER1'=$serverCred1;
	'SAMPLESERVER2'=$serverCred2;
	}

# The number of databases you want to have running at the same time.
$batchingLimit = 10;
# The number of times you want to retry if there is a failure.
$retryLimit = 5;
# The number of minutes you want to wait for an operation to finish before you fail.
$waitInMinutes = 30;

# Connection Asset Name for Authenticating (Keep as AzureClassicRunAsConnection if you created the default RunAs accounts)
$connectionAssetName = "AzureClassicRunAsConnection";

$storageKeyVariableName = "STORAGEKEYVARIABLENAME";
$storageAccountName = "STORAGEACCOUNTNAME";
$storageContainerName = "STORAGECONTAINERNAME";

function LogMessage($message)
{
	$timestamp = Get-Date -format "yyyy-MM-dd_HH:mm.ss";
	echo ($timestamp + " " + $message)
}

# This function takes the database and server names and creates a database object to use for the export.
function CreateDatabaseObject($databaseName, $serverName)
{
	# Create the new object.
	$dbObj = New-Object System.Object;
	# Add the DatabaseName property and set it.
	$dbObj | Add-Member -type NoteProperty -name DatabaseName -Value $databaseName;
	# Add a unique time at the end of DatabaseCopyName so that we have a unique database name every time.
	$currentTime = Get-Date -format "_yyyy-MM-dd_HH:mm.ss";
	$dbCopyName = $databaseName + $currentTime;
	# Add the DatabaseCopyName property and set it.
	$dbObj | Add-Member -type NoteProperty -name DatabaseCopyName -Value $dbCopyName;
	# Add the ServerName property and set it.
	$dbObj | Add-Member -type NoteProperty -name ServerName -Value $serverName;
	# Add the Export property and set it to $null for now. This will be used to look up the export after it has been started.
	$dbObj | Add-Member -type NoteProperty -name Export -Value $null;
	# Add the DatabaseState property and set it to ToCopy so that the "state machine" knows to start the copy of the database.
	$dbObj | Add-Member -type NoteProperty -name DatabaseState -Value ([DatabaseState]::ToCopy);
	# Add the RetryCount property and set it to 0. This will be used to count the number of time we retry each failable operation.
	$dbObj | Add-Member -type NoteProperty -name RetryCount -Value 0;
	# Add the OperationStartTime property and set it to $null for now. This will be used when an operation starts to correcly do timeouts.
	$dbObj | Add-Member -type NoteProperty -name OperationStartTime -Value $null;

	# Return the newly created object.
	return $dbObj;
}

# This function starts the copy of the database. If there is an error, we set the state to ToDrop. Otherwise, we set the state to Copying.
function StartCopy($dbObj)
{
	# Start the copy of the database.
	Start-AzureSqlDatabaseCopy -ServerName $dbObj.ServerName -DatabaseName $dbObj.DatabaseName -PartnerDatabase $dbObj.DatabaseCopyName;
	# $? is true if the last command succeeded and false if the last command failed. If it is false, go to the ToDrop state.
	if(-not $? -and $global:retryLimit -ile $dbObj.RetryCount)
	{
		LogMessage ("Error occurred while starting copy of " + $dbObj.DatabaseName + ". It will not be copied. Deleting the database copy named " + $dbObj.DatabaseCopyName + ".");
		# Set state to ToDrop in case something does get copied.
		$dbsCopying[$i].DatabaseState = ([DatabaseState]::ToDrop);
		# Return so we don't execute the rest of the function.
		return;
	}
	elseif(-not $?)
	{
		# We failed but we haven't hit the retry limit yet so increment RetryCount and return so we try again.
		LogMessage ("Retrying with database " + $dbObj.DatabaseName);
		$dbObj.RetryCount++;
		return;
	}
	# Set the state of the database object to Copying.
	$dbObj.DatabaseState = ([DatabaseState]::Copying);
	LogMessage ("Copying " + $dbObj.DatabaseName + " to " + $dbObj.DatabaseCopyName);
	$dbObj.OperationStartTime = Get-Date;
}

# This function checks the progress of the copy. If there is an error, we set the state to ToDrop. Otherwise, we set the state to ToExport.
function CheckCopy($dbObj)
{
	# Get the status of the database copy.
	$check = Get-AzureSqlDatabaseCopy -ServerName $dbObj.ServerName -DatabaseName $dbObj.DatabaseName -PartnerDatabase $dbObj.DatabaseCopyName;
	$currentTime = Get-Date;
	# $? is true if the last command succeeded and false if the last command failed. If it is false, go to the ToDrop state.
	if((-not $? -and $global:retryLimit -ile $dbObj.RetryCount) -or ($currentTime - $dbObj.OperationStartTime).TotalMinutes -gt $global:waitInMinutes)
	{
		LogMessage ("Error occurred during copy of " + $dbObj.DatabaseName + ". It will not be exported. Deleting the database copy named " + $dbObj.DatabaseCopyName + ".");
		# Set state to ToDrop in case something did get copied.
		$dbsCopying[$i].DatabaseState = ([DatabaseState]::ToDrop);
		# Return so we don't execute the rest of the function.
		return;
	}
	elseif(-not $?)
	{
		# We failed but we haven't hit the retry limit yet so increment RetryCount and return so we try again.
		LogMessage ("Retrying with database " + $dbObj.DatabaseName);
		$dbObj.RetryCount++;
		return;
	}
	# Get the percent complete from the status to check if the database copy is done.
	$i = $check.PercentComplete
	# $i will be $null when the copy is complete.
	if($i -eq $null)
	{
		# The copy is complete so set the state to ToExport.
		$dbObj.DatabaseState = ([DatabaseState]::ToExport);
		$dbObj.RetryCount = 0;
	}
}

# This function starts the export. If there is an error, we set the state to ToDrop. Otherwise, we set the state to Exporting.
function StartExport($dbObj)
{
	# Get the current time to use as a unique identifier for the blob name.
	$currentTime = Get-Date -format "_yyyy-MM-dd_HH:mm.ss";
	$blobName = $dbObj.DatabaseName + "_ExportBlob" + $currentTime;
	# Use the stored credential to create a server credential to use to login to the server.
	$serverCredential = $global:serverCredentialsDictionary[$dbObj.ServerName];
	# Set up a SQL connection context to use when exporting.
	$ctx = New-AzureSqlDatabaseServerContext -ServerName $dbObj.ServerName -Credential $serverCredential;
	# Get the storage key to setup the storage context.
	$storageKey = Get-AutomationVariable -Name $global:storageKeyVariableName;
	# Get the storage context.
	$stgctx = New-AzureStorageContext -StorageAccountName $global:storageAccountName -StorageAccountKey $storageKey;
	# Start the export. If there is an error, stop the export and set the state to ToDrop.
	$dbObj.Export = Start-AzureSqlDatabaseExport -SqlConnectionContext $ctx -StorageContext $stgctx -StorageContainerName $global:storageContainerName -DatabaseName $dbObj.DatabaseCopyName -BlobName $blobName;
	# $? is true if the last command succeeded and false if the last command failed. If it is false, go to the ToDrop state.
	if (-not $? -and $global:retryLimit -ile $dbObj.RetryCount)
	{
		LogMessage ("Error occurred while starting export of " + $dbObj.DatabaseName + ". It will not be exported. Deleting the database copy named " + $dbObj.DatabaseCopyName + ".");
		# Set state to ToDrop so that we drop the copied database since there was an error exporting it.
		$dbsToExport[$i].DatabaseState = ([DatabaseState]::ToDrop);
		# Return so we don't execute the rest of the function.
		return
	}
	elseif(-not $?)
	{
		# We failed but we haven't hit the retry limit yet so increment RetryCount and return so we try again.
		LogMessage ("Retrying with database " + $dbObj.DatabaseName);
		$dbObj.RetryCount++;
		return;
	}
	# Set the state to Exporting.
	$dbObj.DatabaseState = ([DatabaseState]::Exporting);
	LogMessage ("Exporting " + $dbObj.DatabaseCopyName + " with RequestID: " + $dbObj.Export.RequestGuid);
	$dbObj.OperationStartTime = Get-Date;
}

# This function monitors the export progress.
function CheckExport($dbObj)
{
	# Get the progress of the database's export.
	$check = Get-AzureSqlDatabaseImportExportStatus -Request $dbObj.Export;
	$currentTime = Get-Date;
	# The export is complete when Status is "Completed". Wait for that to happen.
	if($check.Status -eq "Completed")
	{
		# The export id one, set the state to ToDrop because it was successful.
		$dbObj.DatabaseState = ([DatabaseState]::ToDrop);
		$dbObj.RetryCount = 0;
	}
	elseif($check.Status -eq "Failed" -and $dbObj.RetryCount -lt $global:retryLimit)
	{
		# If the status is "Failed" and we have more retries left, try to export the database copy again.
		LogMessage ("The last export failed on database " + $dbObj.DatabaseName + ", going back to ToExport state to try again");
		LogMessage $check.ErrorMessage
		$dbObj.DatabaseState = ([DatabaseState]::ToExport);
		$dbObj.RetryCount++;
		return;
	}
	elseif($global:retryLimit -ile $dbObj.RetryCount -or ($currentTime - $dbObj.OperationStartTime).TotalMinutes -gt $global:waitInMinutes)
	{
		LogMessage ("Error occurred while exporting " + $dbObj.DatabaseName + ". Deleting the database copy named " + $dbObj.DatabaseCopyName + ".");
		# The export id one, set the state to ToDrop either because it failed.
		$dbObj.DatabaseState = ([DatabaseState]::ToDrop);
	}
	elseif(-not $?)
	{
		# We failed but we haven't hit the retry limit yet so increment RetryCount and return so we try again.
		LogMessageLogMessage ("Retrying with database " + $dbObj.DatabaseName);
		$dbObj.RetryCount++;
		return;
	}
}

# This function runs the command to drop the database and sets the state to Finished.
function StartDrop($dbObj)
{
	# Start the delete
	Remove-AzureSqlDatabase -ServerName $dbObj.ServerName -DatabaseName $dbObj.DatabaseCopyName -Force;
	# Set the state to Finished so it gets removed from the array.
	$dbObj.DatabaseState = ([DatabaseState]::Finished);
	LogMessage ($dbObj.DatabaseCopyName + " dropped")
}

# Runs the "State Machine" so that different databases can progress independently.
function ExportProcess
{
	# Get all database objects in the ToCopy state and start the database copy.
	$dbsToCopy = $global:dbs | Where-Object DatabaseState -eq ([DatabaseState]::ToCopy);
	for($i = 0; $i -lt $dbsToCopy.Count; $i++)
	{
		LogMessage "Database Name: $($dbsToCopy[$i].DatabaseName) State: $($dbsToCopy[$i].DatabaseState) Retry Count: $($dbsToCopy[$i].RetryCount)";
		StartCopy($dbsToCopy[$i]);
	}
	
	# Get all database objects in the Copying state and check on their copy progress.
	$dbsCopying = $global:dbs | Where-Object DatabaseState -eq ([DatabaseState]::Copying);
	for($i = 0; $i -lt $dbsCopying.Count; $i++)
	{
		CheckCopy($dbsCopying[$i]);
	}
	
	# Get all database objects in the ToExport state and start their export.
	$dbsToExport = $global:dbs | Where-Object DatabaseState -eq ([DatabaseState]::ToExport);
	for($i = 0; $i -lt $dbsToExport.Count; $i++)
	{
		LogMessage "Database Name: $($dbsToExport[$i].DatabaseName) State: $($dbsToExport[$i].DatabaseState) Retry Count: $($dbsToExport[$i].RetryCount)";
		StartExport($dbsToExport[$i]);
	}
	
	# Get all database objects in the Exporting state and check on their export progress.
	$dbsExporting = $global:dbs | Where-Object DatabaseState -eq ([DatabaseState]::Exporting);
	for($i = 0; $i -lt $dbsExporting.Count; $i++)
	{
		CheckExport($dbsExporting[$i]);
	}
	
	# Get all database objects in the ToDrop state and start their drop.
	$dbsToDrop = $global:dbs | Where-Object DatabaseState -eq ([DatabaseState]::ToDrop);
	for($i = 0; $i -lt $dbsToDrop.Count; $i++)
	{
		LogMessage "Database Name: $($dbsToDrop[$i].DatabaseName) State: $($dbsToDrop[$i].DatabaseState) Retry Count: $($dbsToDrop[$i].RetryCount)";
		StartDrop($dbsToDrop[$i]);
	}
	
	# Get all database objects in the Finished state and remove them from the array.
	$dbsFinished = $global:dbs | Where-Object DatabaseState -eq ([DatabaseState]::Finished);
	for($i = 0; $i -lt $dbsFinished.Count; $i++)
	{
		$global:dbs.Remove($dbsFinished[$i]);
	}
}

# Authenticate to Azure with certificate
Write-Verbose "Get connection asset: $connectionAssetName" -Verbose;
$automationConnection = Get-AutomationConnection -Name $connectionAssetName;
if ($automationConnection -eq $null)
{
   throw "Could not retrieve connection asset: $connectionAssetName. Assure that this asset exists in the Automation account.";
}

$certificateAssetName = $automationConnection.CertificateAssetName;
Write-Verbose "Getting the certificate: $certificateAssetName" -Verbose;
$automationCertificate = Get-AutomationCertificate -Name $certificateAssetName;
if ($automationCertificate -eq $null)
{
   throw "Could not retrieve certificate asset: $certificateAssetName. Assure that this asset exists in the Automation account.";
}

Write-Verbose "Authenticating to Azure with certificate." -Verbose;
Set-AzureSubscription -SubscriptionName $automationConnection.SubscriptionName -SubscriptionId $automationConnection.SubscriptionID -Certificate $automationCertificate;
Select-AzureSubscription -SubscriptionId $automationConnection.SubscriptionID;

$currentIndex = 0;
for($currentRun = 0; $currentRun -lt ([math]::Ceiling($databaseServerPairs.Length/$batchingLimit)); $currentRun++)
{
	# Loop through all the databses in the $databaseServerPairs array and add corresponding database objects into the array.
	for($currentIndex; $currentIndex -lt $global:databaseServerPairs.Length -and $currentIndex -lt ($currentRun*$batchingLimit + $batchingLimit); $currentIndex++)
	{
		$global:dbs.Add((CreateDatabaseObject $global:databaseServerPairs[$currentIndex].DatabaseName $global:databaseServerPairs[$currentIndex].ServerName))
	}

	# Continually call ExportProcess until all of the database objects have been removed from the array.
	while($global:dbs.Count -gt 0)
	{
		ExportProcess
	}
}