param (
    [string]$resourceGroupName = '',
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId = '00000000-0000-0000-0000-000000000000',
    [switch]$WhatIf = $false,
    [string]$propertiesJSON = @"
{
    "backupPolicy": null,
    "monitoring": {
        "enabled": false
    },
    "migration": {
        "assessment": {
            "enabled": false
        }
    }
}
"@
)

Write-Verbose "Resource Group Name: $resourceGroupName"
Write-Verbose "Subscription ID: $subscriptionId"
Write-Verbose "WhatIf: $WhatIf"
Write-Verbose "Properties JSON: $propertiesJSON"

$properties = $propertiesJSON | ConvertFrom-Json

try {
    Write-Verbose "Connecting to Azure with subscription ID: $subscriptionId"
    $defaultProfile = Connect-AzAccount -SubscriptionId $subscriptionId -ErrorAction Stop

    if ([string]::IsNullOrEmpty($resourceGroupName)) {
        Write-Verbose "Fetching resources for subscription ID: $subscriptionId"
        $resources = Get-AzResource -ResourceType "Microsoft.AzureArcData/SqlServerInstances"  -ErrorAction Stop -Pre -ExpandProperties
    } else {
        Write-Verbose "Fetching resources for subscription ID: $subscriptionId and resource group: $resourceGroupName"
        $resources = Get-AzResource -ResourceType "Microsoft.AzureArcData/SqlServerInstances" -ErrorAction Stop -Pre -ExpandProperties -ResourceGroupName $resourceGroupName
    }
    $resources = $resources | Where-Object { 'SSIS','SSAS','SSRS' -notcontains $_.Properties.serviceType }

    foreach ($resource in $resources) {
        try {
            if ($WhatIf) {
                Write-Verbose "Performing dry-run patch for resource: $($resource.Id)"
                $resource | Set-AzResource -Properties $properties -UsePatchSemantics -Pre -Force -DefaultProfile $defaultProfile -ErrorAction Stop -WhatIf
            } else {
                Write-Verbose "Patching resource: $($resource.Id)"
                $resource | Set-AzResource -Properties $properties -UsePatchSemantics -Pre -Force -DefaultProfile $defaultProfile -ErrorAction Stop
                Write-Host("Resource patched: $($resource.Id)") 
            }
        } catch {
            Write-Error "Failed to patch resource: $($resource.Id). Error: $_"
        }
    }
} catch {
    Write-Error "An error occurred: $_"
}