#Requires -Modules @{ ModuleName="Az.Sql"; ModuleVersion="3.5.1" }
#Data Sync OMS Integration Runbook

#To use this script Change all the strings below to reflect your information.
#Setup a System Managed Identity in the Automation Account, with Reader permissions to the monitored SQL targets
#Also allow the managed identity access to the Automation Account itself to read/write the Variable used

#Information for Sync Group 1
#If you want to use all the sync groups in your subscription keep the $DS_xxxx fields empty.
#If you want to use all sync groups in a Resource Group define the $DS_ResourceGroupName.
#If you want to use all sync groups in a Server define $DS_ResourceGroupName and $DS_ServerName.
#If you want to use all sync groups in a Database define $DS_ResourceGroupName, $DS_ServerName and $DS_DatabaseName.
#If you want to use a specific sync group define $DS_ResourceGroupName, $DS_ServerName, $DS_DatabaseName and $DS_SyncGroupName.

$SubscriptionId = "SubscriptionId"
$DS_ResourceGroupName = ""
$DS_ServerName =  ""
$DS_DatabaseName = ""
$DS_SyncGroupName = ""

# Insert your Automation Account ResourceGroup and Account names
$AC_ResourceGroupName = "ResourceGroupName"
$AC_AccountName = "AutomationAccountName"
# Insert the name of the DateTime variable in the Automation Account for storing the last synctime
$AC_LastUpdatedTimeVariableName = "DataSyncLogLastUpdatedTime"

# Replace with your OMS Workspace ID (Log Analytics Workspace ID)
$CustomerId = "OMSCustomerID"

# Replace with your OMS Primary Key (Log Analytics Primary Key)
$SharedKey = "SharedKey"

# Specify the name of the record type that you'll be creating
$LogType = "DataSyncLog"

# Specify a field with the created time for the records
$TimeStampField = "DateValue"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

# Create the function to create and post the request
Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}


#Get Log Data
#Set the endtime, get StartTime-filter from Automation Account variable
$endtime =[System.DateTime]::UtcNow
$StartTime = Get-AzAutomationVariable -ResourceGroupName $AC_ResourceGroupName `
                                        –AutomationAccountName $AC_AccountName `
                                        -Name $AC_LastUpdatedTimeVariableName | Select -ExpandProperty Value

#Get Log
Write-Output "Getting Data Sync Log from $StartTime to $EndTime"

if ($DS_ResourceGroupName -eq "")
{
    $ResourceGroupName = Get-AzResourceGroup | select -ExpandProperty ResourceGroupName
}
else
{
    $ResourceGroupName = $DS_ResourceGroupName
}

foreach ($ResourceGroup in $ResourceGroupName)
{
    if ($DS_ServerName -eq "")
    {
        $ServerName = Get-AzSqlServer -ResourceGroupName $ResourceGroup | select -ExpandProperty ServerName
    }
    else
    {
        $ServerName = $DS_ServerName
    }

    foreach ($Server in $ServerName)
    {
        if ($DS_DatabaseName -eq "")
        {
            $DatabaseName = Get-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $Server | select -ExpandProperty DatabaseName
        }
        else
        {
            $DatabaseName = $DS_DatabaseName
        }

        foreach ($Database in $DatabaseName)
        {
            if ($Database -eq "master")
            {
                continue;
            }

            if ($DS_SyncGroupName -eq "")
            {
                $SyncGroupName = Get-AzSqlSyncGroup -ResourceGroupName $ResourceGroup -ServerName $Server -DatabaseName $Database | select -ExpandProperty SyncGroupName
            }
            else
            {
                $SyncGroupName = $DS_SyncGroupName
            }

            foreach ($SyncGroup in $SyncGroupName)
            {
                $Logs = Get-AzSqlSyncGroupLog -ResourceGroupName $ResourceGroup `
                                                  -ServerName $Server `
                                                  -DatabaseName $Database `
                                                  -SyncGroupName $SyncGroup `
                                                  -starttime $StartTime `
                                                  -endtime $EndTime;

                if ($Logs.Length -gt 0)
                {
                foreach ($Log in $Logs)
                {
                    $Log | Add-Member -Name "SubscriptionId" -Value $SubscriptionId -MemberType NoteProperty
                    $Log | Add-Member -Name "ResourceGroupName" -Value $ResourceGroup -MemberType NoteProperty
                    $Log | Add-Member -Name "ServerName" -Value $Server -MemberType NoteProperty
                    $Log | Add-Member -Name "HubDatabaseName" -Value $Database -MemberType NoteProperty
                    $Log | Add-Member -Name "SyncGroupName" -Value $SyncGroup -MemberType NoteProperty

                    #Filter out Successes to Reduce Data Volume to OMS
                    #Include the 5 commented out line below to enable the filter
                    #For($i=0; $i -lt $Log.Length; $i++ ) {
                    #    if($Log[$i].LogLevel -eq "Success") {
                    #      $Log[$i] =""
                    #    }
                    # }



                }


                $json = ConvertTo-JSON $logs



                $result = Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
                if ($result -eq 200)
                {
                    Write-Host "Success"
                }
                if ($result -ne 200)
               {
                   throw
@"
                    Posting to OMS Failed                         
                    Runbook Name: DataSyncOMSIntegration                         
"@
                }
                }
            }
        }
    }
}


# Write runtime into Automation Account variable
Set-AzAutomationVariable -ResourceGroupName $AC_ResourceGroupName `
                          –AutomationAccountName $AC_AccountName `
                          -DefaultProfile $AzureContext `
                          -Name $AC_LastUpdatedTimeVariableName `
                          -Value $EndTime `
                          -Encrypted $False
