<#
.SYNOPSIS
Counts SQL IaaS Agent VM extensions by extension handler version.

.DESCRIPTION
Finds Azure VM extensions where publisher is Microsoft.SqlServer.Management and type is SqlIaaSAgent,
then counts them by installed extension handler version when Azure exposes the version through instanceView.
This script is read-only and works on both Windows and Linux with PowerShell 7.
If SubscriptionId is omitted, the script searches all subscriptions in the logged-in user's access scope.
If ResourceGroupName is provided, SubscriptionId is required and only that resource group is searched.

.PREREQUISITES
- PowerShell 7 or Windows PowerShell 5.1.
- Az.Accounts PowerShell module.
- Az.ResourceGraph PowerShell module.
- An authenticated Azure context from Connect-AzAccount, or another Az.Accounts-supported login method.

.EXAMPLE
.\Get-SqlIaaSAgentExtensionVersionCounts.ps1

.EXAMPLE
.\Get-SqlIaaSAgentExtensionVersionCounts.ps1 -SubscriptionId '00000000-0000-0000-0000-000000000000'

.EXAMPLE
.\Get-SqlIaaSAgentExtensionVersionCounts.ps1 -SubscriptionId '00000000-0000-0000-0000-000000000000' -ResourceGroupName 'my-resource-group'
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $SubscriptionId,

    [Parameter()]
    [string] $ResourceGroupName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ResourceGroupName -and -not $SubscriptionId) {
    throw "SubscriptionId is required when ResourceGroupName is provided."
}

$publisher = 'Microsoft.SqlServer.Management'
$extensionType = 'SqlIaaSAgent'
$computeApiVersion = '2024-07-01'

function Import-RequiredModule {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "Required PowerShell module '$Name' is not installed. Install it with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $Name -ErrorAction Stop
}

function Invoke-ArmGet {
    param(
        [Parameter(Mandatory)]
        [string] $PathOrUri,

        [Parameter()]
        [switch] $AllowNotFound
    )

    if ($PathOrUri -like 'https://*') {
        $response = Invoke-AzRestMethod -Method GET -Uri $PathOrUri
    }
    else {
        $response = Invoke-AzRestMethod -Method GET -Path $PathOrUri
    }

    if ($AllowNotFound -and $response.StatusCode -eq 404) {
        return $null
    }

    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "ARM GET failed with status $($response.StatusCode): $($response.Content)"
    }

    return $response.Content | ConvertFrom-Json
}

function Escape-KustoStringLiteral {
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    return $Value.Replace("'", "''")
}

function Get-ExtensionInstalledVersion {
    param(
        [Parameter(Mandatory)]
        [string] $ExtensionResourceId
    )

    $extensionPath = "$ExtensionResourceId`?api-version=$computeApiVersion&`$expand=instanceView"
    $extension = Invoke-ArmGet -PathOrUri $extensionPath -AllowNotFound

    if (-not $extension) {
        return $null
    }

    $propertiesProperty = $extension.PSObject.Properties['properties']

    if (-not $propertiesProperty) {
        return [pscustomobject]@{
            Version = '<unknown>'
            Source  = 'Unavailable'
        }
    }

    $properties = $propertiesProperty.Value

    $instanceViewProperty = $properties.PSObject.Properties['instanceView']
    if ($instanceViewProperty) {
        $instanceViewVersionProperty = $instanceViewProperty.Value.PSObject.Properties['typeHandlerVersion']
        if ($instanceViewVersionProperty -and $instanceViewVersionProperty.Value) {
            return [pscustomobject]@{
                Version = $instanceViewVersionProperty.Value
                Source  = 'InstanceView'
            }
        }
    }

    $configuredVersionProperty = $properties.PSObject.Properties['typeHandlerVersion']
    if ($configuredVersionProperty -and $configuredVersionProperty.Value) {
        return [pscustomobject]@{
            Version = $configuredVersionProperty.Value
            Source  = 'ConfiguredOnly'
        }
    }

    return [pscustomobject]@{
        Version = '<unknown>'
        Source  = 'Unavailable'
    }
}

function Search-MatchingExtensions {
    param(
        [Parameter(Mandatory)]
        [string] $Query,

        [Parameter(Mandatory)]
        [string] $SubscriptionId
    )

    $pageSize = 1000
    $skip = 0

    do {
        $page = if ($skip -eq 0) {
            @(Search-AzGraph -Query $Query -Subscription $SubscriptionId -First $pageSize -WarningAction SilentlyContinue)
        }
        else {
            @(Search-AzGraph -Query $Query -Subscription $SubscriptionId -First $pageSize -Skip $skip -WarningAction SilentlyContinue)
        }

        $page
        $skip += $page.Count
    } while ($page.Count -eq $pageSize)
}

Import-RequiredModule -Name Az.Accounts
Import-RequiredModule -Name Az.ResourceGraph

if (-not (Get-AzContext)) {
    throw "No Azure context found. Run Connect-AzAccount first, then rerun this script."
}

$subscriptionIds = if ($SubscriptionId) {
    @($SubscriptionId)
}
else {
    @(Get-AzSubscription | Select-Object -ExpandProperty Id)
}

$resourceGroupFilter = if ($ResourceGroupName) {
    "and resourceGroup =~ '$(Escape-KustoStringLiteral -Value $ResourceGroupName)'"
}
else {
    ''
}

$query = @"
Resources
| where type =~ 'microsoft.compute/virtualmachines/extensions'
| where properties.publisher =~ '$publisher'
| where properties.type =~ '$extensionType'
$resourceGroupFilter
| project subscriptionId, resourceGroup, vmName = tostring(split(name, '/')[0]), extensionName = tostring(split(name, '/')[1]), extensionResourceId = id
"@

$matchingExtensions = foreach ($subId in $subscriptionIds) {
    Search-MatchingExtensions -Query $query -SubscriptionId $subId
}

$installedVersions = foreach ($subscriptionGroup in ($matchingExtensions | Group-Object -Property subscriptionId)) {
    Set-AzContext -SubscriptionId $subscriptionGroup.Name -WarningAction SilentlyContinue | Out-Null

    foreach ($extension in $subscriptionGroup.Group) {
        $versionInfo = Get-ExtensionInstalledVersion -ExtensionResourceId $extension.extensionResourceId

        if (-not $versionInfo) {
            Write-Warning "Skipping extension because it was returned by Resource Graph but not found by ARM: $($extension.extensionResourceId)"
            continue
        }

        [pscustomobject]@{
            SubscriptionId    = $extension.subscriptionId
            ResourceGroupName = $extension.resourceGroup
            VMName            = $extension.vmName
            ExtensionName     = $extension.extensionName
            ExtensionVersion  = $versionInfo.Version
            VersionSource     = $versionInfo.Source
        }
    }
}

$installedVersions |
    Group-Object -Property ExtensionVersion, VersionSource |
    Select-Object `
        @{ Name = 'ExtensionVersion'; Expression = { $_.Group[0].ExtensionVersion } },
        @{ Name = 'VersionSource'; Expression = { $_.Group[0].VersionSource } },
        Count,
        @{ Name = 'VersionSort'; Expression = {
            $version = $_.Group[0].ExtensionVersion
            if ($version -match '^\d+(\.\d+){1,3}$') {
                [version] $version
            }
            else {
                [version] '0.0'
            }
        } } |
    Sort-Object -Property VersionSort -Descending |
    Select-Object -Property ExtensionVersion, VersionSource, Count |
    Format-Table -AutoSize
