# Function App that helps automate Managed Instance related tasks

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Deploy and configure this sample](#deploy-configure-this-sample)<br/>
[Run this sample](#run-this-sample)<br/>
[Troubleshoot](#troubleshoot)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

- **Applies to:** Azure SQL Database
- **Key features:**  Managed Instance
- **Workload:** n/a
- **Programming Language:** C#, PowerShell
- **Authors:** Srdan Bozovic
- **Update history:** n/a

This sample shows one approach to Managed Instance management automation using Function App and system-assigned identity.

With system-assigned identity, Function App could be assigned permissions to invoke proper actions in a safe way.

Instead of granting excessive permissions to users, admins could grant required permissions to Function App that exposes very restrained set of functionalities through API. Code running on Function App doesn't have any secrets configured or hardcoded.

Currently available functions:
- Assign Azure AD Directory Readers permissions to Managed Instance principal

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. PowerShell 5.1 or higher
2. Azure PowerShell 5.4.2 or higher
3. Visual Studio 2017

**Azure prerequisites:**

Person who does the setup needs to have following rights:

1. Azure AD `Privileged Role Administrator` role
2. Permissions to add `Readers` permission for Function App principal on any of the following scopes: Managed Instance, Resource group, Subscription. Associated scope depends on deployment and security policies.

<a name=deploy-configure-this-sample></a>

## Deploy and configure this sample

Steps below show how to deploy pre-build package. Alternatively you could deploy Function App using Visual Studio and source code provided with this sample.

1. Create Function App by following [Create your first function in the Azure portal](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function) quickstart
2. Download [package](./zip-deploy/ManagedInstanceAutomationDemo.zip?raw=true).
3. Publish package using [Azure CLI](https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push#cli), with [cURL](https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push#with-curl) or with [PowerShell](https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push#with-powershell)
4. Grant access to Function App by following [Grant access](https://docs.microsoft.com/en-us/azure/role-based-access-control/quickstart-assign-role-user-portal#grant-access). For easier selection, choose `Function App` in `Assign access to` dropbox. It might take up to an hour for this permission grant to become effective.
5. Add system-assigned identity by following [Adding a system-assigned identity](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity?toc=%2fazure%2fazure-functions%2ftoc.json#adding-a-system-assigned-identity) and note generated `Object ID`.
6. Run PowerShell below to provide Function App required Azure AD permissions.

```powershell

Connect-AzureAD

$managedInstanceAutomationObjectId = '<function-app-object-id>'

# Get Azure AD role "Privileged Role Administrator" and create if it doesn't exist
$roleName = "Privileged Role Administrator"
$role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq $roleName}
if ($role -eq $null) {
    # Instantiate an instance of the role template
    $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.displayName -eq $roleName}
    Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
    $role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq $roleName}
}

# Check if service principal is already member of "Privileged Role Administrator" role
$allRoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
$selectedRoleMember = $allRoleMembers | where{$_.ObjectId -match $managedInstanceAutomationObjectId}

if ($selectedRoleMember -eq $null)
{
    # Add principal to "Privileged Role Administrator" role
    Write-Output "Adding service principal to 'Privileged Role Administrator' role..."
    Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $managedInstanceAutomationObjectId
    Write-Output "Service principal added to 'Privileged Role Administrator' role'."
}
else
{
    Write-Output "Service principal is already member of 'Privileged Role Administrator' role'."
}

```

### Note

In step 3. use `Get publish profile` to get user name and password. If you are using PowerShell to upload package, put user name and password under single quotes as with double quotes character `$` has special meaning.

<a name=run-this-sample></a>

## Run this sample

Function App exposes functionality through REST API. Sample below shows how you could invoke function using PowerShell. [Here](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function#test-the-function) you can find how to get Function App key.

This [article](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/azure-function?view=azdevops) shows how you can invoke Function App from Azure Pipeline | TFS 2018 | TFS 2017.

```powershell

$subscriptionId = "<subscription-id>"
$resourceGroupName = "<managed-instance-resource-group>"
$managedInstanceName = "<managed-instance-name>"

$functionAppName = "<function-app-name>"
$code = "<function-app-key>"

$managedInstanceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/managedInstances/$managedInstanceName"
$apiUrl="https://$functionAppName.azurewebsites.net/api/AssignDirectoryReadersRoleFunction?code=$code"
$body =  @{id=$managedInstanceId} | ConvertTo-Json

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod $apiUrl -Method POST -ContentType "application/json" -Body $body

```

<a name=troubleshoot></a>

## Troubleshoot

If Function App is not configured or doesn't run properly you will get HTTP 400 error with error message in plain text.

Below is list of errors with actions to resolve them.

#### Managed Service Identity (MSI) is not assigned.

Add system-asigned identity as described at step 5. in [deploy and configure this sample](#deploy-configure-this-sample) section.

#### [Forbidden]: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Sql/managedInstances/{name}'.

Function App doesn't have permissions to read Managed Instance properties. Add permission as described at step 4. in [deploy and configure this sample](#deploy-configure-this-sample) section.

#### [Not Found]: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Sql/managedInstances/{name}'.

Function App doesn't have permissions to read Managed Instance properties. Add permission as described at step 4. in [deploy and configure this sample](#deploy-configure-this-sample) section.

#### [MSI Not Assigned]: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Sql/managedInstances/{name}'.

Managed Instance you want to enable for Azure AD authentication doesn't have it's own system-asigned identity (this is different from first error in this section where Function App doesn't have identity assigned).

#### [Forbidden]: '/{tenantId}/directoryRoles'.

Function App doesn't have permissions to read Azure AD. Add permission as described at step 6. in [deploy and configure this sample](#deploy-configure-this-sample) section.

<a name=disclaimers></a>

## Disclaimers
The scripts and this guide are copyright Microsoft Corporations and are provided as samples. They are not part of any Azure service and are not covered by any SLA or other Azure-related agreements. They are provided as-is with no warranties express or implied. Microsoft takes no responsibility for the use of the scripts or the accuracy of this document. Familiarize yourself with the scripts before using them.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For more information, see these articles:

- [Azure SQL Database Managed Instance](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-index)
- [Configure and manage Azure Active Directory authentication with SQL](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-aad-authentication-configure)
- [How to use managed identities for App Service and Azure Functions](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity)