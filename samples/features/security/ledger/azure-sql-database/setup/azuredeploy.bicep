///////////////////////
// Define parameters //
///////////////////////

@description('The project name. The names of all resources will be derived from the project name.')
param projectName string

@description('The object id of the user running the deployment.')
param userObjectId string

@description('The username of the user running the deployment.')
param userName string

@description('The username of the Azure SQL database server administrator for SQL authentication.')
param sqlAdminUserName string

@description('The password of the Azure SQL database server administrator for SQL authentication.')
param sqlAdminPassword string

@description('The IP address the user will connect from to the logical server in Azure SQL Database.')
param clientIP string

@description('The location (the Azure region) for all resources.')
param location string = resourceGroup().location


////////////////////////////////////////////
// Create and configure a logical server //
////////////////////////////////////////////

// Create the server
var SQLServerName_var = '${projectName}server'
#disable-next-line BCP081
resource Server_Name_resource 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: SQLServerName_var
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlAdminUserName
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Allow Azure services and resources to access this server
#disable-next-line BCP081
resource Server_Name_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = {
  name: '${Server_Name_resource.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Allow Client IP to access this server
#disable-next-line BCP081
resource Server_Name_AllowClientIP 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = {
  name: '${Server_Name_resource.name}/AllowClientIP'
  properties: {
    endIpAddress: clientIP
    startIpAddress: clientIP
  }
}

// Make the user an Azure AD administrator for the server, so that the user can connect with universal authentication
#disable-next-line BCP081
resource Server_Name_activeDirectory 'Microsoft.Sql/servers/administrators@2021-08-01-preview' = {
  name: '${Server_Name_resource.name}/activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: userName
    //sid: reference(resourceId('Microsoft.Sql/servers', '${projectName}server'), '2019-06-01-preview', 'Full').identity.principalId
    sid: userObjectId
    //tenantId: AAD_TenantId //optional
  }
}

///////////////////////////////////
// Create the ContosoHR database//
//////////////////////////////////
#disable-next-line BCP081
resource Database_Resource 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: 'ContosoHR'
  parent: Server_Name_resource
  location: location
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
}

////////////////////////////////////////////
// Enable automated ledger digest storage//
//////////////////////////////////////////

//Create a storage account to store ledger digests
var StorageAccount_var = '${projectName}stg'
#disable-next-line BCP081
resource StorageAccount_Resource 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: StorageAccount_var
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_RAGRS'
  }
  dependsOn: [
    Database_Resource
  ]
}

//Grant the server access to the storage account
var roleDefinitionId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // this is Storage Blob Data Contributor's GUID from https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
#disable-next-line BCP081
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, resourceGroup().name, StorageAccount_var)
  scope: StorageAccount_Resource
  properties: {
    principalId:  Server_Name_resource.identity.principalId
    roleDefinitionId:  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

//Enable ledger digest uploads
#disable-next-line BCP081
resource LedgerDigestUploads_Resource 'Microsoft.Sql/servers/databases/ledgerDigestUploads@2021-08-01-preview' = {
  name: 'current'
  parent: Database_Resource
  properties: {
    digestStorageEndpoint: '${StorageAccount_Resource.properties.primaryEndpoints.blob}'
  }
}


///////////////////////////////////
// Configure the web application //
///////////////////////////////////

// Create an App Service plan
resource WebAppServicePlan_Resource 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${projectName}plan'
 location: location
 properties: {}
  sku: {
    name: 'B1'
  }
}

// Create the App Service
resource WebApp_Resource 'Microsoft.Web/sites@2021-02-01' = {
  name: '${projectName}app'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: WebAppServicePlan_Resource.id
 }

 //Set the database connection string for the application

 resource WebAppConnectionString_Resource 'config' = {
  name: 'connectionstrings'
  properties: {
    ContosoHRDatabase: {
      value: 'Server=tcp:${Server_Name_resource.properties.fullyQualifiedDomainName};Database=ContosoHR; Authentication=Active Directory Managed Identity'
      type: 'SQLAzure'
    }
  }
 }
  //Define AppSetting to fetch the correct project from the GitHub Repository
 resource AppSetting 'config' = {
  name: 'appsettings'
  properties: {
    PROJECT: 'samples/features/security/ledger/source/ContosoHR/ContosoHR.csproj'
  }
 }
}

 // Deploy the application
resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2021-02-01' = {
  name: '${projectName}app/web'
  properties: {
    repoUrl: 'https://github.com/microsoft/sql-server-samples.git'
    branch: 'master'
    isManualIntegration: true
  }
  dependsOn: [
         Server_Name_resource
       ]
}

output Servername    string = Server_Name_resource.properties.fullyQualifiedDomainName
output DatabaseName  string = 'ContosoHR'
output appname string = '${projectName}app'
