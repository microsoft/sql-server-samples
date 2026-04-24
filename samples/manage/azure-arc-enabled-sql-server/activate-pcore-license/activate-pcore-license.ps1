.<#
    .DESCRIPTION
        This runbook activates a SQL Server license using the Managed Identity
        The runbook accepts the following parameters:

    -LicenseID            (The license resource URI)

    .NOTES
        AUTHOR: Alexander (Sasha) Nosov
        LASTEDIT: June 24, 2024
#>

param (
    [Parameter (Mandatory= $true)]
    [string] $LicenseId
)

#
# Suppress warnings
#
Update-AzConfig -DisplayBreakingChangeWarning $false

# Logging in to Azure..."    
try
{
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$currentLicense = Get-AzResource -ResourceId $LicenseId 
$currentLicense.properties.activationState = "Activated"
$currentLicense | Set-AzResource -Force

