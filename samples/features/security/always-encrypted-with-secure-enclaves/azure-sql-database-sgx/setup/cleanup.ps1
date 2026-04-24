Import-Module "Az.Resources"

######################################################################
# Prompt the user to enter the values of deployment parameters
######################################################################

$resourceGroupName = Read-Host -Prompt "Enter the resource group name"
$subscriptionId = Read-Host -Prompt "Enter your subscription id"

######################################################################
# Sign in to Azure
######################################################################

Connect-AzAccount
$context = Set-AzContext -Subscription $subscriptionId

######################################################################
# Delete the resource group and the key vault with purge proteciton on
######################################################################

$location = (Get-AzResourceGroup -Name $resourceGroupName).Location
Remove-AzResourceGroup -Name $resourceGroupName
Remove-AzKeyVault -VaultName "${resourceGroupName}vault" -InRemovedState -Location $location