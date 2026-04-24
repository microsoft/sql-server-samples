<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.Parameter MachineName
    The name of the Arc Sql Server-enabled machine on which to update extension settings.
.Parameter resourceGroup
    The Azure resource group hosting the machine.
.PARAMETER Subscription
    The Azure subscription for the machine.
.PARAMETER FeatureFlagsToEnable
    Optional. Array of the names of feature flags to be enabled in the extension's settings.
    Unknown feature flags will generate a warning, and may generate a prompt to continue
    (unless the Force flag is provided).
.PARAMETER FeatureFlagsToDisable
    Optional. Array of the names of feature flags to be disabled in the extension's settings.
    Unknown feature flags will generate a warning, and may generate a prompt to continue
    (unless the Force flag is provided).
.PARAMETER Force
    Optional. Provide the Force flag to update the settings even if unrecognized feature flags
    are provided.
.PARAMETER DryRun
    Optional. Provide the DryRun flag to retrieve current settings and modify them, but do not
    send the modified settings to the extension. DryRun can be used to verify changes before
    executing them.
.EXAMPLE
    To enable the SqlManagement and AG discovery features in your subscription 
    in resource group contoso-rg for machine contoso-sql-host, the command would be:
    set-feature-flags.ps1 `
       -Subscription "<Your-subscription-ID>" `
       -ResourceGroup "contoso-rg" `
       -MachineName "contoso-sql-host" `
       -FeatureFlagsToEnable ("SqlManagement")

.NOTES
    Author: Sarah Feitler
    Date:   September 2023   
#>
param(
	[Parameter (Mandatory = $true)]
    [string] $Subscription,
    [Parameter (Mandatory = $true)]
    [string] $ResourceGroup,
    [Parameter (Mandatory = $true)]
    [string] $MachineName,
    [Parameter (Mandatory = $false)]
    [string[]] $FeatureFlagsToEnable,
    [Parameter (Mandatory = $false)]
    [string[]] $FeatureFlagsToDisable,
    [Parameter (Mandatory = $false)]
    [switch] $Force,
    [Parameter (Mandatory = $false)]
    [switch] $DryRun
)

# This list comes from the Azure Sql Server Extension project, and may not be up-to-date.
$knownFeatureFlags = "AvailabilityGroupDiscovery", "SqlManagement", "SqlFailoverClusterInstanceDiscovery"

$mysteryFlagsList = New-Object System.Collections.ArrayList

if ($FeatureFlagsToEnable -ne $null)
{
    $FeatureFlagsToEnable = $FeatureFlagsToEnable | Get-Unique
    # using output as a throwaway to control console output
    $output = $FeatureFlagsToEnable | Where-Object {
        if ( $_ -notin $knownFeatureFlags )
        {
            $mysteryFlagsList.Add("$_ ")
            $true
        }
        else
        {
            $false
        }
    }
}
if ($FeatureFlagsToDisable -ne $null)
{
    $FeatureFlagsToDisable = $FeatureFlagsToDisable | Get-Unique
    # using output as a throwaway to control console output
    $output = $FeatureFlagsToDisable | Where-Object {
        if ( $_ -notin $knownFeatureFlags )
        {
            $mysteryFlagsList.Add("$_ ")
            $true
        }
        else
        {
            $false
        }
    }
}

if ($mysteryFlagsList.Count -gt 0)
{
    Write-Host ("Warning, the following flags were not found in known list of feature flags: $mysteryFlagsList")
    if ($Force -eq $false) {
        $confirmation = Read-Host "Do you want to continue executing the script? (Y/N)"
        # Check the user's response
        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
            # User wants to continue, script execution continues
            Write-Host "Continuing..."
        } else {
            # User chose not to continue, so exit the script
            Write-Host "Exiting"
            exit 1
        }
    }
}

$connectedMachineExtension = az extension list | where-object {$_ -like "*connectedmachine*"} 
if($connectedMachineExtension.Count -eq 0){
    Write-Output "connectedmachine extension is not installed.  Please run the following command to install it before running this script."
    Write-Output "az extension add -n connectedmachine"
    Exit 1
}

# Retrieve current settings and convert to a powershell object
$jsonData = az connectedmachine extension show --name "WindowsAgent.SqlServer" --machine-name $machineName --resource-group $ResourceGroup --subscription $Subscription | Join-String

if (! $?)
{
    Write-Host
    Write-Host "Error on extension show. Exiting."
    exit 1
}

try {
    $object = $jsonData | ConvertFrom-Json
}
catch {
    Write-Output "Failed to retrieve valid json.  This may be caused because the connectedmachine extension was not properly installed prior to running the script.  Please run the script again."
    Exit 1
}

if($null -eq $object.properties.settings.FeatureFlags)
{
    # create new featureFlags array if it does not exist.
    $object.properties.settings | Add-Member -Name "FeatureFlags" -Value @() -MemberType NoteProperty 
}

# Check if FeatureFlagsToEnable or FeatureFlagsToDisable arrays are specified
if ($FeatureFlagsToEnable -ne $null -or $FeatureFlagsToDisable -ne $null) {
    $foundFeatureFlags = $object.properties.settings.FeatureFlags.Name

    if ($FeatureFlagsToEnable -ne $null) {
        foreach ($flagToEnable in $FeatureFlagsToEnable) {
            if ($flagToEnable -in $foundFeatureFlags) {
                # Update the Enable property for the flag
                $object.properties.settings.FeatureFlags | Where-Object { $_.Name -eq $flagToEnable } | ForEach-Object { $_.Enable = $true }
            } else {
                # Create a new entry for the flag
                $newFlag = @{
                    Enable = $true
                    Name = $flagToEnable
                }
                $object.properties.settings.FeatureFlags += $newFlag
            }
        }
    }

    if ($FeatureFlagsToDisable -ne $null) {
        foreach ($flagToDisable in $FeatureFlagsToDisable) {
            if ($flagToDisable -in $foundFeatureFlags) {
                # Update the Enable property for the flag
                $object.properties.settings.FeatureFlags | Where-Object { $_.Name -eq $flagToDisable } | ForEach-Object { $_.Enable = $false }
            } else {
                # Create a new entry for the flag
                $newFlag = @{
                    Enable = $false
                    Name = $flagToDisable
                }
                $object.properties.settings.FeatureFlags += $newFlag
            }
        }
    }
}else{
    Write-Output "No feature flags were enabled or disabled."
    Exit
}

# Convert the settings section of the modified object back to JSON
$currentSettings = $object.properties.settings
$updatedJsonData = $currentSettings | ConvertTo-Json -Depth 10

Write-Host "Updated settings: $updatedJsonData"
Set-Content -Path .\patchedJson.json -Value $updatedJsonData

if ( $DryRun -eq $False )
{
    write-host "This may take up to 5 minutes to complete.  Please wait."
    az connectedmachine extension update `
        --name "WindowsAgent.SqlServer" `
        --type "WindowsAgent.SqlServer" `
        --publisher "Microsoft.AzureData" `
        --settings patchedJson.json  `
        --machine-name $machineName `
        --resource-group $resourceGroup `
        --subscription $subscription
    Write-Host "Updated settings in extension"
}
else
{
    Write-Host "DryRun run done. Updated settings can be viewed in the file $pwd\patchedjson.json"
}
