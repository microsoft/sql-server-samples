
<#
.SYNOPSIS
    Updates the license type for Azure Arc SQL resources to a specified license and license related options.  

.DESCRIPTION
    The script updates the license related settings of the SQL extension resources in a specified Entra ID tenant. You can specify a particular subscription, resource group or an individual connected machine. 
    You can also provide a list of subscriptions as a .CSV file. 
    By default, all subscriptions in your current tenant id are scanned.

.VERSION
    3.0.5 - Initial version.

.PARAMETER SubId
    A single subscription ID or a CSV file name containing a list of subscriptions.

.PARAMETER ResourceGroup
    Optional. Limit the scope to a specific resource group.

.PARAMETER MachineName 
    Optional. A single machine name or a CSV file name containing a list of machine names.

.PARAMETER LicenseType
    Optional. License type to set. Allowed values: "PAYG", "Paid" or "LicenseOnly"

.PARAMETER ConsentToRecurringPAYG 
    Optional. Consents to enabling the recurring PAYG billing. LicenseType must be "PAYG". Applies to CSP subscriptions only.

.PARAMETER UsePcoreLicense
    Optional. Opts in to use unlimited virtualization license if the value is "Yes", or opts out if the value is "No". To opt in, the license type must be "Paid" or "PAYG"

.PARAMETER EnableESU
    Optional. Enables the ESU policy if the value is "Yes" or disables it if the value is "No". To enable, the license type must be "Paid" or "PAYG"

.PARAMETER Force
    Optional. Forces the change of the license type to the specified value on all installed extensions. If not forced, the changes will apply only to the extensions where the license type is undefined.    

.PARAMETER ExclusionTags
    Optional. If specified, excludes the resources that have this tag assigned.

.PARAMETER TenantId
    Optional. If specified, this tenant id to log in both PowerShell and CLI. Otherwise, the current login context is used.

.PARAMETER ReportOnly
    Optional. If true, generates a csv file with the list of resources that are to be modified, but doesn't make the actual change.

.PARAMETER UseManagedIdentity
    Optional. If true, logs in both PowerShell and CLI using managed identity. Required to run the script as a runbook.

.PARAMETER WaitForCompletion
    Optional. If specified, waits for each submitted extension update to reach a terminal
    provisioning state and reports the confirmed outcome, instead of returning as soon as the
    request is accepted. Extension updates are normally submitted with -NoWait, so by default
    the report records "RequestSubmitted", which means the service accepted the request - not
    that the Arc agent has applied it. Use this switch when you need confirmed results;
    it makes the run substantially slower because each machine is polled individually.

.PARAMETER WaitTimeoutSeconds
    Optional. Maximum number of seconds to wait per resource when -WaitForCompletion is used.
    Defaults to 300. Reaching the timeout is not treated as a failure: the outcome is recorded
    as "TimedOut" because the update may still be applied by the agent afterwards.

#>

param (
    [Parameter (Mandatory=$false)]
    [string] $SubId,

    [Parameter (Mandatory= $false)]
    [string] $ResourceGroup,

    [Parameter (Mandatory= $false)]
    [string] $MachineName,

    [Parameter (Mandatory= $false)]
    [ValidateSet("PAYG","Paid","LicenseOnly", IgnoreCase=$false)]
    [string] $LicenseType,

    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $ConsentToRecurringPAYG,
    
    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $UsePcoreLicense,

    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $EnableESU,

    [Parameter (Mandatory= $false)]
    [switch] $Force,

    [Parameter (Mandatory= $false)]
    [object] $ExclusionTags,

    [Parameter (Mandatory= $false)]
    [string] $TenantId,

    [Parameter (Mandatory= $false)]
    [switch] $ReportOnly,
   
    [Parameter (Mandatory= $false)]
    [switch] $UseManagedIdentity,

    [Parameter (Mandatory= $false)]
    [switch] $WaitForCompletion,

    [Parameter (Mandatory= $false)]
    [int] $WaitTimeoutSeconds = 300,

    [Parameter (Mandatory= $false)]
    [int] $batchSize = 500
)

# Transcription is not available in every host (for example Azure Automation
# runbooks) and can also fail if the log path is not writable. Track whether it
# actually started so the matching Stop-Transcript at the end of the script does
# not throw "The host is not currently transcribing".
$transcriptStarted = $false
try {
    Start-Transcript -Path ".\modify-arc-sql-license-type.log" -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
} catch {
    Write-Warning "Unable to start transcript logging: $($_.Exception.Message) Continuing without a transcript."
}
$scriptStartTime = Get-Date
Write-Output "Script execution started at: $($scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

<#
.SYNOPSIS
    Polls an Arc machine extension until its provisioning state is terminal.
.DESCRIPTION
    Extension updates are submitted with -NoWait, so the service accepting the request says
    nothing about whether the Arc agent applied it. When -WaitForCompletion is used this
    polls the extension and reports the confirmed outcome.

    A timeout is deliberately NOT reported as a failure: the agent may still apply the
    setting after the script gives up, so the run is recorded as inconclusive rather than
    unsuccessful.
#>
function Wait-ArcExtensionProvisioning {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][string]$MachineName,
        [Parameter(Mandatory = $true)][string]$ExtensionName,
        [Parameter(Mandatory = $true)][string]$ExpectedLicenseType,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    $terminalStates = @('Succeeded', 'Failed', 'Canceled')
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $delay = 5
    $lastState = 'Unknown'

    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $delay
        try {
            $current = Get-AzConnectedMachineExtension -ResourceGroupName $ResourceGroupName `
                -MachineName $MachineName -Name $ExtensionName -ErrorAction Stop
        } catch {
            return [PSCustomObject]@{ Result = 'Failed'; ErrorMessage = $_.Exception.Message; State = 'Unknown' }
        }

        $lastState = "$($current.ProvisioningState)"

        if ($terminalStates -contains $lastState) {
            if ($lastState -ne 'Succeeded') {
                return [PSCustomObject]@{ Result = 'Failed'; ErrorMessage = "Extension provisioning state is '$lastState'."; State = $lastState }
            }

            # A 'Succeeded' provisioning state only means the extension settings were written.
            # Confirm the value actually reflects the requested license type.
            $applied = $null
            if ($null -ne $current.Setting) {
                try { $applied = "$($current.Setting['LicenseType'])" } catch { $applied = $null }
            }

            if ([string]::IsNullOrEmpty($applied)) {
                return [PSCustomObject]@{ Result = 'Succeeded'; ErrorMessage = ''; State = $lastState }
            }
            if ($applied -eq $ExpectedLicenseType) {
                return [PSCustomObject]@{ Result = 'Succeeded'; ErrorMessage = ''; State = $lastState }
            }
            return [PSCustomObject]@{
                Result       = 'Failed'
                ErrorMessage = "Extension reported '$lastState' but LicenseType is '$applied' instead of '$ExpectedLicenseType'."
                State        = $lastState
            }
        }

        # Back off gradually to avoid hammering the API on slow agents.
        if ($delay -lt 30) { $delay = [Math]::Min(30, $delay * 2) }
    }

    return [PSCustomObject]@{
        Result       = 'TimedOut'
        ErrorMessage = "Did not reach a terminal provisioning state within $TimeoutSeconds seconds (last state: '$lastState'). The update may still be applied by the agent."
        State        = $lastState
    }
}


function Connect-Azure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $TenantId = $null,

        [Parameter(Mandatory=$false)]
        [switch] $UseManagedIdentity
    )

    # 1) Detect host environment
    $envType = 'Local'
    if ($env:AZUREPS_HOST_ENVIRONMENT -like 'cloud-shell*') {
        $envType = 'CloudShell'
    }
    elseif (($env:AZUREPS_HOST_ENVIRONMENT -like 'AzureAutomation*') -or $PSPrivateMetadata.JobId) {
        $envType = 'AzureAutomation'
        $UseManagedIdentity = $true
    }
    Write-Output "Environment detected: $envType"

    # 2) Ensure Az.PowerShell context. Use login V1
    Update-AzConfig -LoginExperienceV2 Off
    $currentCtx = Get-AzContext -ErrorAction SilentlyContinue
    if ($currentCtx -and $currentCtx.Account) {
        if ($TenantId) {
            if ($currentCtx.Tenant.Id -eq $TenantId) {
                Write-Output "Already in Az tenant $TenantId"
            }
            else {
                Write-Output "Switching Az context to tenant $TenantId without re-authentication"
                $newContext = Set-AzContext -Tenant $TenantId -ErrorAction SilentlyContinue
                if($null -eq $newContext -or $newContext.TenantId -ne $TenantId)
                {
                  Connect-AzAccount -Tenant $TenantId  | Out-Null
                }
            } 
        }
        else {
            Write-Output "Using existing Az context: Tenant $($currentCtx.Tenant.Id)"
        }
    }
    else {
        Write-Output "Not connected to Azure PowerShell. Running Connect-AzAccount..."
        if ($UseManagedIdentity) {
            if ($TenantId) {
                Connect-AzAccount -Identity -Tenant $TenantId  | Out-Null
            }
            else {
                Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
            }
        }
        else {
            if ($TenantId) {
                Connect-AzAccount -Tenant $TenantId | Out-Null
            }
            else {
                Connect-AzAccount | Out-Null
            }
        }
        $ctx = Get-AzContext
        Write-Output "Connected to Az PowerShell as: $($ctx.Account) in tenant $($ctx.Tenant.Id)"
    }
}


# Convert to hashtable explicitly
$tagTable = @{}
if($null -ne $ExclusionTags){
    if($ExclusionTags.GetType().Name -eq "Hashtable"){
        $tagTable = $ExclusionTags    
    }else{
        ($ExclusionTags | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
            $tagTable[$_.Name] = $_.Value
        }
    }
}
# Ensure connection with both PowerShell and CLI.
if($UseManagedIdentity -or $envType -eq 'AzureAutomation') {
    if ($TenantId) {
        Connect-Azure -TenantId $TenantId -UseManagedIdentity $UseManagedIdentity
    } else {
        Connect-Azure -UseManagedIdentity $UseManagedIdentity
    }
} else {
    if ($TenantId) {
        Connect-Azure -TenantId $TenantId
    } else {
        Connect-Azure
    }
}

$context = Get-AzContext -ErrorAction SilentlyContinue
Write-Output "Connected to Azure as: $($context.Account)"

if (-not $TenantId) {
    $TenantId = $context.Tenant.Id
    Write-Output "No TenantId provided. Using current context TenantId: $TenantId"
} else {
    Write-Output "Using provided TenantId: $TenantId"
}


# Ensure the required modules are imported

try{
    Import-Module Az.Accounts
}catch{
    Write-Output "Can't import module Az.Accounts"
}
try{
    Import-Module Az.ConnectedMachine
}
catch{
    Write-Output "Can't import module Az.ConnectedMachine"
}
try{
    Import-Module Az.ResourceGraph
}
catch{
    Write-Output "Can't import module Az.ResourceGraph"
}

$modifiedResources = @()

if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne "") {
    Write-Output "Passed Subscription $($SubId)"
    $subscriptions = Get-AzSubscription -SubscriptionId $SubId
}else {
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }
}

# Handle MachineName input (single or CSV)
$machineNames = @()
if ($MachineName) {
    if ($MachineName -like "*.csv") {
        try {
            $machines = Import-Csv $MachineName
            foreach ($m in $machines) {
                if ($m.MachineName) {
                    $machineNames += $m.MachineName
                }
            }
            Write-Output "Loaded $($machineNames.Count) machine names from CSV."
        } catch {
            Write-Error "Failed to import machine names from CSV: $_"
            exit 1
        }
    } else {
        $machineNames += $MachineName
    }
}

Write-Host ([Environment]::NewLine + "-- Scanning subscriptions --")

foreach ($sub in $subscriptions) {
    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id #Removed TenantID by Sunil
    }catch {
        write-host "Invalid subscription: $($sub.Id)"
        {continue}
    }

    Write-Output "Collecting list of resources to update"

    $query = "
    resources
    | where subscriptionId =~ '$($sub.Id)'
    | where type == 'microsoft.hybridcompute/machines'
    | where properties.detectedProperties.mssqldiscovered == 'true'"
    if ($ResourceGroup) {
        $query += "
    | where resourceGroup =~ '$ResourceGroup'"
    }

    if ($machineNames.Count -gt 0) {
        $machineFilter = ($machineNames | ForEach-Object { "'$_'" }) -join ", "
        $query += "| where name in~ ($machineFilter)"
    }

    $query += "
    | extend machineId = tolower(tostring(id))
    | project machineId, machineName = tolower(name)
    | join kind= inner (
        resources
        | where subscriptionId =~ '$($sub.Id)'
        | where type == 'microsoft.hybridcompute/machines/extensions'
        | where properties.publisher =~ 'Microsoft.AzureData'
        | where properties.provisioningState == 'Succeeded'
        | where properties.settings.LicenseType!='$LicenseType'
        | extend extensionName = name
        | extend extensionPublisher = properties.publisher
        | extend extensionType = properties.type
        | parse id with '/subscriptions/' subscriptionId '/resourceGroups/' resourceGroup '/providers/Microsoft.HybridCompute/machines/' machineNameRaw '/extensions/' extensionName
        | extend machineName = tolower(machineNameRaw)
        ) on `$left.machineName == `$right.machineName
    | project machineName, extensionName, resourceGroup, location, subscriptionId, extensionPublisher, extensionType
    | order by machineName asc"
   
    $skipToken = $null

    Write-Output $query

    $allResults = [System.Collections.Generic.List[PSObject]]::new()
    do{
        $resources = Search-AzGraph -Query "$($query)" -First $batchSize -SkipToken $skipToken
        $allResults.AddRange($resources)
        $skipToken = $resources.SkipToken
    }while($skipToken)

    Write-Output "Found $($allResults.Count) resource(s) to update"


    $count = $allResults.Count

    
    while($count -gt 0) {
        $count-=1
        $setID = @{
            MachineName = $allResults[$count].MachineName
            Name = $allResults[$count].extensionName
            ResourceGroup = $allResults[$count].resourceGroup
            Location = $allResults[$count].location
            SubscriptionId = $allResults[$count].subscriptionId
            Publisher = $allResults[$count].extensionPublisher
            ExtensionType = $allResults[$count].extensionType
        }

        write-Output "   MachineName - $($setID.MachineName)"
        write-Output "   ResourceGroup - $($setID.ResourceGroup)"
        write-Output "   Location - $($setID.Location)"
        write-Output "   SubscriptionId - $($setID.SubscriptionId)"
        write-Output "   ExtensionType - $($setID.ExtensionType)"
        
        # Get connected machine info
        $sqlvm = Get-AzConnectedMachine -Name $setID.MachineName -ResourceGroup $setID.ResourceGroup | Select-Object Name, Tags, Status

        
        $excludedByTags = $false
        foreach ($tag in $tagTable.Keys){
            if($sqlvm.Tags.ContainsKey($tag))
            {
                if($sqlvm.Tags[$tag] -eq $tagTable[$tag]){
                    $excludedByTags=$true
                    $value = $tagTable[$tag]
                    write-Output "Exclusion tag $($tag):$value. Skipping..."
                    Break;
                }
            }
        }
        if(!$excludedByTags){
           
        
        $WriteSettings = $false
        $ext = Get-AzConnectedMachineExtension -Name $setID.Name -ResourceGroupName $setID.ResourceGroup -MachineName $setID.MachineName

        # Collect data before modification. UpdateResult/UpdateError are populated
        # after the actual Set-AzConnectedMachineExtension call below (or left as
        # "NotAttempted" if the resource was skipped) so the CSV/console output
        # reflects what actually happened, not just what was intended.
        $resourceRecord = [PSCustomObject]@{
            TenantID            = $TenantId
            SubID               = $setID.SubscriptionId
            ResourceName        = $setID.MachineName
            ResourceType        = $setID.ExtensionType
            Status              = $sqlvm.Status
            OriginalLicenseType = $ext.Setting["LicenseType"]
            ResourceGroup       = $setID.ResourceGroup
            Location            = $setID.Location
            UpdateResult        = "NotAttempted"
            UpdateError         = ""
            # Cores             <To be added>
        }
        $modifiedResources += $resourceRecord

        if($ext.ProvisioningState -ne "Succeeded") {
            write-Output "Extension is not in a valid state. Skipping..."
            {continue}
        } else {
            $LO_Allowed = (!$ext.Setting["enableExtendedSecurityUpdates"] -and !$EnableESU) -or  ($EnableESU -eq "No")
            
            if ($LicenseType) {
                if (($LicenseType -eq "LicenseOnly") -and !$LO_Allowed) {
                    write-Output "ESU must be disabled before license type can be set to $($LicenseType)"
                } else {
                    if ($ext.Setting["LicenseType"]) {
                        if ($Force) {
                            $ext.Setting["LicenseType"] = $LicenseType
                            $WriteSettings = $true
                        }
                    } else {
                        $ext.Setting["LicenseType"] = $LicenseType
                        $WriteSettings = $true
                    }
                }
            }
            
            if ($EnableESU) {
                if (($ext.Setting["LicenseType"] -in ("Paid","PAYG")) -or  ($EnableESU -eq "No")) {
                    $ext.Setting["enableExtendedSecurityUpdates"] = ($EnableESU -eq "Yes")
                    $ext.Setting["esuLastUpdatedTimestamp"] = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    $WriteSettings = $true
                } else {
                    write-Output "The configured license type does not support ESUs" 
                }
            }
            
            if ($UsePcoreLicense) {
                if (($ext.Setting["LicenseType"] -in ("Paid","PAYG")) -or  ($UsePcoreLicense -eq "No")) {
                    $ext.Setting["UsePhysicalCoreLicense"] = @{
                        "IsApplied" = ($UsePcoreLicense -eq "Yes");
                        "LastUpdatedTimestamp" = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    }
                    $WriteSettings = $true
                } else {
                    write-Output "The configured license type does not support ESUs" 
                }
            }
            
            # Add or update ConsentToRecurringPAYG setting if applicable
            if ($ConsentToRecurringPAYG -eq "Yes") {
                $isPayg = ($LicenseType -eq "PAYG") -or ($ext.Setting["LicenseType"] -eq "PAYG")
                if ($isPayg) {
                    if (-not $ext.Setting.ContainsKey("ConsentToRecurringPAYG") -or -not $ext.Setting["ConsentToRecurringPAYG"]["Consented"]) {
                        $ext.Setting["ConsentToRecurringPAYG"] = @{
                            "Consented" = $true;
                            "ConsentTimestamp" = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
                        }
                        $WriteSettings = $true
                    }
                }
            }

            write-Output "   Write Settings - $($WriteSettings)"

            if (-not $ReportOnly) {
                If ($WriteSettings) {
                    try {
                        $settings = @{}
                        foreach ($h in $ext.Setting.Keys) {
                           $settings[$h]=$($ext.Setting[$h])
                        }
                        # -ErrorAction Stop is required here: Set-AzConnectedMachineExtension
                        # can emit a non-terminating error (e.g. "An extension of type ... is
                        # still processing. Only one instance of an extension may be in
                        # progress at a time...") which, combined with -NoWait, would otherwise
                        # be printed to the console and then fall through to the "Updated"
                        # success message below without ever entering the catch block.
                        Set-AzConnectedMachineExtension -Name $setID.Name -ResourceGroupName $setID.ResourceGroup -Location $setID.Location -MachineName $setID.MachineName -Publisher $setID.Publisher -ExtensionType $setID.ExtensionType -Setting $settings -NoWait -ErrorAction Stop
                        Write-Output "Updated -- Resource group: [$($setID.ResourceGroup)], Connected machine: [$($setID.MachineName)]"
                        $resourceRecord.UpdateResult = "RequestSubmitted"

                        if ($WaitForCompletion) {
                            Write-Output "   Waiting for the extension update on [$($setID.MachineName)] to complete (timeout ${WaitTimeoutSeconds}s)..."
                            $wait = Wait-ArcExtensionProvisioning -ResourceGroupName $setID.ResourceGroup `
                                -MachineName $setID.MachineName -ExtensionName $setID.Name `
                                -ExpectedLicenseType "$($settings['LicenseType'])" -TimeoutSeconds $WaitTimeoutSeconds

                            $resourceRecord.UpdateResult = $wait.Result
                            $resourceRecord.UpdateError = $wait.ErrorMessage

                            switch ($wait.Result) {
                                'Succeeded' { Write-Output "   Confirmed -- [$($setID.MachineName)] provisioning state '$($wait.State)'." }
                                'TimedOut'  { Write-Warning "Timed out waiting for [$($setID.MachineName)]: $($wait.ErrorMessage)" }
                                default     { Write-Warning "The extension update for [$($setID.MachineName)] did not succeed: $($wait.ErrorMessage)" }
                            }
                        }
                    } catch {
                        $errorMessage = $_.Exception.Message
                        Write-Output "The request to modify the extension object for [$($setID.MachineName)] failed with the following error: $errorMessage"
                        $resourceRecord.UpdateResult = "Failed"
                        $resourceRecord.UpdateError = $errorMessage
                        continue
                    }
                }
            } else {
                Write-Output "ReportOnly mode enabled. Skipping modification for: $($setID.MachineName)"
            }
        }
        
    }
    }
}

# Export modified resource data to CSV
if ($modifiedResources.Count -gt 0) {
    $csvPath = "ModifiedResources_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $modifiedResources | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Output "CSV report saved to: $csvPath"
} else {
    Write-Output "No resources were marked for modification. No CSV generated."
}

write-Output "Arc SQL Update Script completed"

$scriptEndTime = Get-Date
$executionDuration = $scriptEndTime - $scriptStartTime
Write-Output "Script execution ended at: $($scriptEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "Total execution time: $($executionDuration.ToString('hh\:mm\:ss'))"
if ($transcriptStarted) {
    try { Stop-Transcript | Out-Null } catch { Write-Warning "Unable to stop transcript logging: $($_.Exception.Message)" }
}
