<#
.SYNOPSIS
    Schedules or executes pay-transition operations for Azure and/or Arc.

.DESCRIPTION
    Depending on parameters, this script either:
      - Downloads and runs the Azure and/or Arc pay-transition scripts once, or
      - Registers a Windows Scheduled Task to invoke itself daily at 2 AM.

.PARAMETER Target
    Which environment(s) to process:
      - Arc
      - Azure
      - Both

.PARAMETER RunMode
    Whether to run immediately or schedule recurring runs:
      - Single     : Download & invoke once, then exit.
      - Scheduled  : Create or update the scheduled task calling this script daily.

.EXAMPLE
    # Run immediately for both Azure and Arc
    .\manage-payg-transition.ps1 -Target Both -RunMode Single

.EXAMPLE
    # Schedule daily runs for Azure only
    .\manage-payg-transition.ps1 -Target Azure -RunMode Scheduled
#>

param(
    [Parameter(Mandatory, Position=0)]
    [ValidateSet("Arc","Azure","Both")]
    [string]$Target,

    [Parameter(Mandatory, Position=1)]
    [ValidateSet("Single","Scheduled")]
    [string]$RunMode,

    [Parameter(Mandatory = $false, Position=2)]
    [bool]$cleanDownloads=$false,

    [Parameter (Mandatory= $false)]
    [ValidateSet("Yes","No", IgnoreCase=$false)]
    [string] $UsePcoreLicense="No",

    [Parameter(Mandatory=$false)]
    [string]$targetResourceGroup=$null,

    [Parameter(Mandatory=$false)]
    [string]$targetSubscription=$null,

    [Parameter(Mandatory=$true)]
    [string]$AutomationAccResourceGroupName,

    [Parameter(Mandatory=$false)]
    [string]$AutomationAccountName="aaccAzureArcSQLLicenseType",

    [Parameter(Mandatory=$true)]
    [string]$Location=$null
)
$git = "sql-server-samples"
$environment = "microsoft"
if($null -ne $env:MYAPP_ENV) {
    $git = "arc-sql-dashboard"
    $environment = $env:MYAPP_ENV
}
# === Configuration ===
$scriptUrls = @{
    General = @{
        URL = "https://raw.githubusercontent.com/$($environment)/$($git)/refs/heads/master/samples/manage/azure-hybrid-benefit/modify-license-type/set-azurerunbook.ps1"
        Args = @{
            ResourceGroupName= "'$($AutomationAccResourceGroupName)'"
            AutomationAccountName= $AutomationAccountName 
            Location= $Location
            targetResourceGroup= $targetResourceGroup
            targetSubscription= $targetSubscription}
        }
    Azure = @{
        URL = "https://raw.githubusercontent.com/$($environment)/$($git)/refs/heads/master/samples/manage/azure-hybrid-benefit/modify-license-type/modify-azure-sql-license-type.ps1"
        Args = @{
            Force_Start_On_Resources = $true
            SubId = [string]$targetSubscription
            ResourceGroup = [string]$targetResourceGroup
        }
    }
    Arc   = @{
        URL = "https://raw.githubusercontent.com/$($environment)/$($git)/refs/heads/master/samples/manage/azure-hybrid-benefit/modify-license-type/modify-arc-sql-license-type.ps1"
        Args =@{
            LicenseType= "PAYG"
            Force = $true
            UsePcoreLicense=[string]$UsePcoreLicense
            SubId = [string]$targetSubscription
            ResourceGroup = [string]$targetResourceGroup
        }
   }
}
# Define a dedicated download folder
$downloadFolder = './manage-payg-transition/'
# Ensure destination folder exists
if (-not (Test-Path $downloadFolder)) {
    Write-Host "Creating folder: $downloadFolder"
    New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null
}
# Helper to download a script and invoke it
function Invoke-RemoteScript {
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [Parameter(Mandatory)]
        [ValidateSet("Arc","Azure","Both")]
        [string]$Target,
        [Parameter(Mandatory)]
        [ValidateSet("Single","Scheduled")]
        [string]$RunMode
    )
    $fileName = Split-Path $Url -Leaf
    $dest     = Join-Path $downloadFolder $fileName

    
    Write-Host "Downloading $Url to $dest..."
    Invoke-RestMethod -Uri $Url -OutFile $dest

    $scriptname = $dest
    $wrapper = @()
    $wrapper += @"
    `$ResourceGroupName= '$($AutomationAccResourceGroupName)'
    `$AutomationAccountName= '$AutomationAccountName' 
    `$Location= '$Location'
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "`$targetResourceGroup= '$targetResourceGroup'" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "`$targetSubscription= '$targetSubscription'" })
"@
    if($Target -eq "Both" -or $Target -eq "Arc") {

        $supportfileName = Split-Path $scriptUrls.Arc.URL -Leaf
        $supportdest     = Join-Path $downloadFolder $supportfileName
        Write-Host "Downloading $($scriptUrls.Arc.URL) to $supportdest..."
        Invoke-RestMethod -Uri $scriptUrls.Arc.URL -OutFile $supportdest

        $supportfileName = Split-Path $scriptUrls.Azure.URL -Leaf
        $supportdest     = Join-Path $downloadFolder $supportfileName
        Write-Host "Downloading $scriptUrls.Azure.URL to $supportdest..."
        Invoke-RestMethod -Uri $scriptUrls.Azure.URL -OutFile $supportdest

        $nextline = if(($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") -or ($null -ne $targetSubscription -and $targetSubscription -ne "")) {"``"}
        $nextline2 = if(($null -ne $targetSubscription -and $targetSubscription -ne "")){"``"}
        $wrapper += @"
`$RunbookArg =@{
LicenseType= 'PAYG'
Force = `$true
$(if ($null -ne $UsePcoreLicense) { "UsePcoreLicense='$UsePcoreLicense'" } else { "" })
$(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "SubId='$targetSubscription'" })
$(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "ResourceGroup='$targetResourceGroup'" })
}

    $scriptname -ResourceGroupName `$ResourceGroupName -AutomationAccountName `$AutomationAccountName -Location `$Location -RunbookName 'ModifyLicenseTypeArc' ``
    -RunbookPath '$(Split-Path $scriptUrls.Arc.URL -Leaf)' ``
    -RunbookArg `$RunbookArg $($nextline)
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "-targetResourceGroup `$targetResourceGroup $nextline2" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "-targetSubscription `$targetSubscription" })
"@

    }

    if($Target -eq "Both" -or $Target -eq "Azure") {

        $supportfileName = Split-Path $scriptUrls.Azure.URL -Leaf
        $supportdest     = Join-Path $downloadFolder $supportfileName
        Write-Host "Downloading $($scriptUrls.Azure.URL) to $supportdest..."
        Invoke-RestMethod -Uri $scriptUrls.Azure.URL -OutFile $supportdest

        $nextline = if(($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") -or ($null -ne $targetSubscription -and $targetSubscription -ne "")) {"``"}
        $nextline2 = if(($null -ne $targetSubscription -and $targetSubscription -ne "")){"``"}
        $wrapper += @"
`$RunbookArg =@{
    Force_Start_On_Resources = `$true
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "ResourceGroup= '$targetResourceGroup'" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "SubId= '$targetSubscription'" })

}

$scriptname     -ResourceGroupName `$ResourceGroupName -AutomationAccountName `$AutomationAccountName -Location `$Location -RunbookName 'ModifyLicenseTypeAzure' ``
    -RunbookPath '$(Split-Path $scriptUrls.Azure.URL -Leaf)'``
    -RunbookArg `$RunbookArg $($nextline)
    $(if ($null -ne $targetResourceGroup -and $targetResourceGroup -ne "") { "-targetResourceGroup `$targetResourceGroup $nextline2" })
    $(if ($null -ne $targetSubscription -and $targetSubscription -ne "") { "-targetSubscription `$targetSubscription" })
        
"@

    }
    $wrapper | Out-File -FilePath './runnow.ps1' -Encoding UTF8
    .\runnow.ps1
}

# === Single run: download & invoke the appropriate script(s) ===
if($RunMode -eq "Single") {
    $wrapper = @()
    if ($Target -eq "Both" -or $Target -eq "Arc") {
        $fileName = Split-Path $scriptUrls.Arc.URL -Leaf
        $dest     = Join-Path $downloadFolder $fileName

        
        $wrapper +="$dest ``" 
        foreach ($arg in $scriptUrls.Arc.Args.Keys) {
            if ("" -ne $scriptUrls.Arc.Args[$arg]) {
                $wrapper+="-$($arg)='$($scriptUrls.Arc.Args[$arg])'"
            }   
        }
    }

    if ($Target -eq "Both" -or $Target -eq "Azure") {
        $fileName = Split-Path $scriptUrls.Azure.URL -Leaf
        $dest     = Join-Path $downloadFolder $fileName

       
        $wrapper +="$dest ``" 
        foreach ($arg in $scriptUrls.Azure.Args.Keys) {
            if ("" -ne $scriptUrls.Azure.Args[$arg]) {
                $wrapper+="-$($arg)='$($scriptUrls.Azure.Args[$arg])'"
            }   
        }
    }

    $wrapper | Out-File -FilePath './runnow.ps1' -Encoding UTF8 
    .\runnow.ps1

    Write-Host "Single run completed."
}else{
    Write-Host "Run 'Scheduled'."
    Invoke-RemoteScript -Url $scriptUrls.General.URL -Target $Target -RunMode $RunMode
}
# === Cleanup downloaded files & folder ===
if($cleanDownloads -eq $true) {
    if (Test-Path $downloadFolder) {
        Write-Host "Cleaning up downloaded scripts in $downloadFolder..."
        try {
            Remove-Item -Path $downloadFolder -Recurse -Force
            Write-Host "Cleanup successful: removed $downloadFolder"
        }
        catch {
            Write-Warning "Cleanup failed: $_"
        }
    }
}