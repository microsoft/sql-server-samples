<#
.SYNOPSIS
    Delete the Azure resource group created by create-resources.ps1.

.PARAMETER ResourceGroup
    Name of the resource group to delete. Default: rg-sql-vector-quickstart

.EXAMPLE
    ./scripts/delete-resources.ps1
    ./scripts/delete-resources.ps1 -ResourceGroup "my-rg"
#>
param(
    [string]$ResourceGroup = "rg-sql-vector-quickstart"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "Delete Azure Resources"
Write-Host "============================================================"
Write-Host "  Resource group: $ResourceGroup"
Write-Host ""

$confirm = Read-Host "Are you sure you want to delete '$ResourceGroup'? [y/N]"
if ($confirm -notmatch '^[Yy]$') {
    Write-Host "Aborted."
    exit 0
}

Write-Host ""
Write-Host "Deleting resource group: $ResourceGroup..."
az group delete `
    --name $ResourceGroup `
    --yes `
    --no-wait

Write-Host "Resource group deletion started (runs in background)."
Write-Host ""
Write-Host "Note: Azure OpenAI resources are soft-deleted. To fully purge, run:"
Write-Host "  az cognitiveservices account list-deleted --query `"[].name`" -o tsv"
Write-Host "  az cognitiveservices account purge --name <name> --resource-group $ResourceGroup --location <location>"
Write-Host ""
Write-Host "Done."
