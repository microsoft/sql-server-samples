param (
[string]$resourceGroupName,
[Parameter(Mandatory=$true)]
[string]$subscriptionId,
[bool]$whatIf = $false
)

if ([string]::IsNullOrEmpty($subscriptionId)) {
    $subscriptionId = Read-Host -Prompt "Please enter the subscription ID"
}

# if ([string]::IsNullOrEmpty($resourceGroupName)) {
#     $resourceGroupName = Read-Host -Prompt "Please enter the resource group name"
# }

if ([string]::IsNullOrEmpty($whatIf)) {
    $dryRun = Read-Host -Prompt "Would you like to run this as a dry run? (yes/no)"
    if ($dryRun -eq "yes") {
            $whatIf = $true
        } else {
            $whatIf = $false
        }
}

Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "Subscription ID: $subscriptionId"
Write-Host "WhatIf: $WhatIf"

if ([string]::IsNullOrEmpty($subscriptionId)) {
    Write-Host "The subscription ID is required."
    exit
} 

$minSupportedApiVersion = '2024-07-10'
$query = $null
$resources = $null

if ([string]::IsNullOrEmpty($resourceGroupName)){
    $query ="
    Resources 
    | where type =~ 'microsoft.azurearcdata/sqlserverinstances' 
    | where subscriptionId =~ '$subscriptionId' 
    | project name, resourceGroup
    "
} else {
    $query ="
    Resources 
    | where type =~ 'microsoft.azurearcdata/sqlserverinstances' 
    | where resourceGroup =~ '$resourceGroupName' 
    | where subscriptionId =~ '$subscriptionId' 
    | project name, resourceGroup
    "
}

$resources = Search-AzGraph -Query $query

if ([string]::IsNullOrEmpty($resources)) {
    Write-Host "No SQL Server Instances were found in this scope."
    exit
}

$resources = $resources | ForEach-Object {
    [pscustomobject]@{
        ResourceGroup  = $_.resourceGroup
        SqlArcResource = $_.name
    }
}

$arcMachineResourceIds = @()
foreach ($resource in $resources) {
    Write-Host "ResourceGroup: $($resource.ResourceGroup), Sql Arc resource: $($resource.SqlArcResource)"

    $hybridComputeResourceId = Get-AzResource -ResourceName $resource.SqlArcResource -ResourceGroupName $resource.ResourceGroup -ResourceType "Microsoft.AzureArcData/sqlServerInstances" | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty containerResourceId
    $arcMachineResourceIds += $hybridComputeResourceId
}

$arcMachineUniqueResourceIds = $arcMachineResourceIds | Get-Unique
Write-Output "Arc Machine Resource Ids:"
Write-Output $arcMachineUniqueResourceIds

foreach ($arcMachineUniqueResourceId in $arcMachineUniqueResourceIds) {
    Write-Host "----- Attempting to remove settings from machine: $($arcMachineUniqueResourceId) -----"
    $computeMachineResource = Get-AzResource -ResourceId "$arcMachineUniqueResourceId"
    $extensionResource = Get-AzResource -ResourceId "$arcMachineUniqueResourceId/extensions/WindowsAgent.SqlServer" -ApiVersion $minSupportedApiVersion
    $currentSettings = $extensionResource.properties.settings

    $parsedData = @{
        "ExtensionAgentStatus" = $null
        "TimestampUTC" = $null
    }

    if ($extensionResource.properties.instanceView.status -match "SQL Server Extension Agent: (\w+);") {
        $parsedData["ExtensionAgentStatus"] = $matches[1]
    }

    if ($extensionResource.properties.instanceView.status -match "timestampUTC : ([\d\/:., ]+);") {
        $parsedData["TimestampUTC"] = [datetime]::ParseExact($matches[1], "yyyy/MM/dd, HH:mm:ss.fff", $null) 
    }

    # Check if the Extension Agent is healthy and the timestamp is within the last 24 hours
    $extensionAgentHealthy = $parsedData["ExtensionAgentStatus"] -eq "Healthy"
    $timestampWithin24Hours = ($parsedData["TimestampUTC"] -gt (Get-Date).AddHours(-24))

    if ($computeMachineResource.properties.status -ne "Connected") {
        Write-Host "This machine has status: $($computeMachineResource.properties.status). We will skip removing the configurations on this machine."
        continue
    } elseif (-not ($extensionAgentHealthy -and $timestampWithin24Hours)) {
        Write-Host "The extension agent status is: $($parsedData["ExtensionAgentStatus"]) and was last updated: $($($parsedData["TimestampUTC"]))."
        Write-Host "The extension status must be healthy and updated within 24hrs for us to proceed. We will skip removing the configurations on this machine."
        continue
    } else {
        Write-Host "This machine has status: $($computeMachineResource.properties.status). We will proceed to remove the configurations."
    }

    # Disable ESU
    if ($currentSettings.PSobject.Properties.Name -contains "EnableExtendedSecurityUpdates") {
        $currentSettings.EnableExtendedSecurityUpdates = $false
    }
    # Disable Microsoft Updates
    if ($currentSettings.PSobject.Properties.Name -contains "MicrosoftUpdateConfiguration") {
        $currentSettings.MicrosoftUpdateConfiguration.EnableMicrosoftUpdate = $false
    }
    # Disable BPA
    if ($currentSettings.PSobject.Properties.Name -contains "AssessmentSettings") {
        $currentSettings.AssessmentSettings.Enable = $false
    }

    $newProperties = $extensionResource.properties
    $newProperties.settings = $currentSettings

    $newProperties | ConvertTo-Json | Out-File "settingsInFile.json"

    try {
        if ($whatIf) {
	        $extensionResource | Set-AzResource -Properties $newProperties -UsePatchSemantics -Pre -ErrorAction Stop -WhatIf -AsJob
        } else {
            $extensionResource | Set-AzResource -Properties $newProperties -UsePatchSemantics -Pre -ErrorAction Stop -Force -AsJob
        }
        Write-Host "Command executed."
    } catch {
        Write-Host "Command failed with the following error:"
        Write-Host $_.Exception.Message
    }
}