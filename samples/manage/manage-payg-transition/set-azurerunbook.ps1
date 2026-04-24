<#
.SYNOPSIS
    Creates or uses an Azure Automation account and imports a runbook.

.DESCRIPTION
    This script:
      - Connects to Azure (PowerShell + CLI).
      - Creates the resource group if it doesn't exist.
      - Creates the Automation account (with system identity) if it doesn't exist.
      - Assigns a set of built‑in roles to that managed identity.
      - Imports or updates the specified runbook, publishes it.
      - Creates a daily schedule (if missing) and links it to the runbook.
      - Starts a one‑off job of the runbook.

.PARAMETER ResourceGroupName
    The resource group in which to create/use the Automation account.

.PARAMETER AutomationAccountName
    The Automation account name.

.PARAMETER Location
    Azure region for the RG and account (e.g. "EastUS").

.PARAMETER RunbookName
    The name under which to import/publish the runbook.

.PARAMETER RunbookPath
    Full path to the local .ps1 runbook file.

.PARAMETER RunbookType
    Runbook type: "PowerShell", "PowerShell72", "PowerShellWorkflow", "Graph", "Python2", or "Python3".
    Default: "PowerShell72".

.PARAMETER targetResourceGroup
    (Optional) Resource group passed into the runbook as a parameter.

.PARAMETER targetSubscription
    (Optional) Subscription ID passed into the runbook as a parameter.
#>

param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AutomationAccountName,
    [Parameter(Mandatory)][string]$Location,
    [Parameter(Mandatory)][string]$RunbookName,
    [Parameter(Mandatory)][string]$RunbookPath,
    [Parameter()][Hashtable]$RunbookArg,
    [ValidateSet("PowerShell","PowerShell72","PowerShellWorkflow","Graph","Python2","Python3")]
    [string]$RunbookType = "PowerShell72",
    [string]$targetResourceGroup,
    [string]$targetSubscription
)
# Suppress unnecessary logging output
$VerbosePreference      = "SilentlyContinue"
$DebugPreference        = "SilentlyContinue"
$ProgressPreference     = "SilentlyContinue"
$InformationPreference  = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"
$context = $null
# Define role assignments to apply
$roleAssignments = @(
    @{ RoleName = "SQL DB Contributor"; Description = "For Azure SQL Databases and Azure SQL Elastic Pools" },
    @{ RoleName = "SQL Managed Instance Contributor"; Description = "For Azure SQL Managed Instances and Azure SQL Instance Pools" },
    @{ RoleName = "Data Factory Contributor"; Description = "For Azure Data Factory SSIS Integration Runtimes" },
    @{ RoleName = "Virtual Machine Contributor"; Description = "For SQL Servers in Azure Virtual Machines" },
    @{RoleName = "SQL Server Contributor"; Description = "For Elastic-Pools in Azure Virtual Machines"},
    @{RoleName = "Azure Connected Machine Resource Administrator"; Description = "For SQL Servers in Arc Virtual Machines"},
    @{RoleName = "Reader"; Description = "For read resources in the subscription"}
)
function Connect-Azure {
        try {
            Write-Output "Testing if it is connected to Azure."
            # Attempt to retrieve the current Azure context
            $context = Get-AzContext -ErrorAction SilentlyContinue
    
            if ($null -eq $context -or $null -eq $context.Account) {
                Write-Output "Not connected to Azure. Executing Connect-AzAccount..."
                if($UseManageIdentity){
                    Connect-AzAccount -Identity -ErrorAction Stop  | Out-Null
                } else {
                    Connect-AzAccount -ErrorAction Stop  | Out-Null
                }
                $context = Get-AzContext
                Write-Output "Connected to Azure as: $($context.Account)"
            }
            else {
                Write-Output "Already connected to Azure as: $($context.Account)"
            }
        }
        catch {
            Write-Error "An error occurred while testing the Azure connection: $_"
        }
        # Ensure the user is logged in to Azure
        try {
            $account = az account show 2>$null | ConvertFrom-Json
            if ($account) {
                Write-Output "Logged in as: $($account.user.name)"
            }
        } catch {
            Write-Output "Not logged in. Run 'az login'."
            if($UseManageIdentity){
                az login --Identity  | Out-Null
            } else {    
                az login  | Out-Null
            }
        }
    }
    function LoadAzModules {
        param(
            [Parameter(Mandatory)][string]$SubscriptionId,
            [Parameter(Mandatory)][string]$ResourceGroupName,
            [Parameter(Mandatory)][string]$AutomationAccountName
        )
        
        
        # List of modules to import from PSGallery
        $modules = @(
            'AzureAD',
            'Az.Accounts',
            'Az.ConnectedMachine',
            'Az.ResourceGraph'
        )
        try {
            $existing = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                -AutomationAccountName $AutomationAccountName -Name $mod -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Output "Removing existing Automation module '$mod'..." -ForegroundColor Magenta
                Remove-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName -Name $mod -Force
                    Write-Output "  → Removed '$mod'." -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Could not check/remove existing module '$mod': $_"
        }

        foreach ($mod in $modules) {
            # Remove existing module from Automation account, if present
            try {
                $existing = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName -Name $mod -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Output "Removing existing Automation module '$mod'..." -ForegroundColor Magenta
                    Remove-AzAutomationModule -ResourceGroupName $ResourceGroupName `
                        -AutomationAccountName $AutomationAccountName -Name $mod -Force
                        Write-Output "  → Removed '$mod'." -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Could not check/remove existing module '$mod': $_"
            }
            Write-Output "Resolving latest version for module '$mod' from PowerShell Gallery..." -ForegroundColor Yellow
            try {
                $info = Find-Module -Name $mod -Repository PSGallery -ErrorAction Stop
                $version = $info.Version.ToString()
                $contentUri = "https://www.powershellgallery.com/api/v2/package/$mod/$version"
                Write-Output "Importing '$mod' version $version into Automation account..." -ForegroundColor Cyan
                Import-AzAutomationModule `
                    -ResourceGroupName     $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName `
                    -Name                  $mod `
                    -ContentLinkUri        $contentUri `
                    -RuntimeVersion    5.1 `
                    -ErrorAction Stop | Out-Null
                    
                    Import-AzAutomationModule `
                    -ResourceGroupName     $ResourceGroupName `
                    -AutomationAccountName $AutomationAccountName `
                    -Name                  $mod `
                    -ContentLinkUri        $contentUri `
                    -RuntimeVersion    7.2 `
                    -ErrorAction Stop | Out-Null
        
                Write-Output "  → Queued '$mod' v$version for import." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to import module '$mod': $_"
            }
        }
        
        Write-Output "All specified modules have been queued for import. Check the Automation account in the portal for status." -ForegroundColor Cyan
        }
# Connect to Azure.
Write-Output "Connecting to Azure..."
Connect-Azure
$context = Get-AzContext -ErrorAction Stop
if ($null -ne $targetSubscription -and $targetSubscription -ne $context.Subscription.Id -and $targetSubscription -ne "") {
    $context = Set-AzContext -Subscription  $targetSubscription -ErrorAction Stop
}

# Check if the resource group exists; if not, create it.
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating Resource Group '$ResourceGroupName' in region '$Location'..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location  | Out-Null
}
else {
    Write-Output "Resource Group '$ResourceGroupName' already exists."
}

# Check if the Automation Account exists; if not, create it.
$automationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction SilentlyContinue
if ($null -eq $automationAccount) {
    Write-Output "Automation Account '$AutomationAccountName' not found. Creating it..."
    $automationAccount = New-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -Location $Location -AssignSystemIdentity 
} else {
    Write-Output "Automation Account '$AutomationAccountName' already exists."
}
if (-not (Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name 'Az.ResourceGraph')) {
    Import-AzAutomationModule `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name 'Az.ResourceGraph' `
    -ContentLinkUri "https://www.powershellgallery.com/packages/Az.ResourceGraph/1.2.0"
    -ErrorAction Stop
}
LoadAzModules -SubscriptionId $context.Subscription.Id -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
# Assign roles to the Automation Account's system-assigned managed identity.
$principalId = $automationAccount.Identity.PrincipalId
$Scope = "/subscriptions/$($context.Subscription.Id)"
Write-Output $principalId 
if ($null -eq $principalId) {
    Write-Output "The Automation Account does not have a system-assigned managed identity enabled." -ForegroundColor Yellow
    exit
} else {
    Write-Output "Automation Account Object ID (PrincipalId): $principalId" -ForegroundColor Green
    foreach ($assignment in $roleAssignments) {
        $roleName = $assignment.RoleName
        
        try {
            if($null -eq (Get-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName $roleName  -Scope $Scope)) {
                Write-Output "Assigning role '$roleName' to Managed Identity '$AutomationAccountName' at scope '$Scope'..." -ForegroundColor Yellow
                New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName $roleName -Scope "/subscriptions/$($context.Subscription.Id)"   -ErrorAction Stop  | Out-Null
                Write-Output "Role '$roleName' assigned successfully." -ForegroundColor Green
                continue
            }
            
        }
        catch {
            Write-Error "Failed to assign role '$roleName': $_"
        }
    }
}
$downloadFolder = './PayTransitionDownloads/'
# Import the runbook into the Automation Account.
if ((Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction SilentlyContinue)) {
    Write-Output "Removing old Runbook '$RunbookName' from Automation Account '$AutomationAccountName'..."
    Remove-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $RunbookName -ResourceGroupName $ResourceGroupName -Force -ErrorAction SilentlyContinue | Out-Null
}
if (-not (Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -ErrorAction SilentlyContinue)) {
    Write-Output "Importing Runbook '$RunbookName' from file '$RunbookPath' into Automation Account '$AutomationAccountName'..."
    Import-AzAutomationRunbook -AutomationAccountName $AutomationAccountName `
        -Name $RunbookName `
        -ResourceGroupName $ResourceGroupName `
        -Path "$($downloadFolder)$($RunbookPath)" `
        -Type $RunbookType `
        -Force `
        -Published `
        -LogProgress $True   | Out-Null
    }


# Create a daily schedule for the runbook (if it doesn't exist).
$ScheduleName = "$($RunbookName)_defaultschedule"
if (-not (Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue)) {
    Remove-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue -Force | Out-Null
}
if (-not (Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating schedule '$ScheduleName'..."
    # Set the schedule to start 5 minutes from now and expire in one year, with daily frequency.
    New-AzAutomationSchedule `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Name $ScheduleName `
        -StartTime (Get-Date).AddDays(1)`
        -WeekInterval 1 `
        -DaysOfWeek @([System.DayOfWeek]::Monday..[System.DayOfWeek]::Sunday) `
        -TimeZone 'UTC' `
        -Description 'Default schedule for runbook'   | Out-Null
} 


# Link the schedule to the runbook, including the sample parameters.
Write-Output "Assigning schedule '$ScheduleName' to runbook '$RunbookName' with sample parameters..."
Register-AzAutomationScheduledRunbook `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -RunbookName $RunbookName `
    -ScheduleName $ScheduleName `
    -Parameters $RunbookArg  | Out-Null

Start-AzAutomationRunbook `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name $RunbookName `
    -Parameters $RunbookArg `
    -ErrorAction SilentlyContinue | Out-Null

Write-Output "Runbook '$RunbookName' has been imported and published successfully."
