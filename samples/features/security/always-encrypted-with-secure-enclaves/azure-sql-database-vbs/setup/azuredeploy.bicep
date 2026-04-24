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
@secure()
param sqlAdminPassword string

@description('The IP address the user will connect from to the logical server in Azure SQL Database.')
param clientIP string

@description('The location (the Azure region) for all resources.')
param location string = resourceGroup().location


////////////////////////////////////////////
// Create and configure a logical server //
////////////////////////////////////////////

// Create the server
var SQLServerName = '${projectName}server'
resource Server_Name_resource 'Microsoft.Sql/servers@2023-02-01-preview' = {
  name: SQLServerName
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlAdminUserName
    administratorLoginPassword: sqlAdminPassword
    //version: 'string' //optional
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Allow Azure services and resources to access this server
resource Server_Name_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = {
  parent: Server_Name_resource
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Allow Client IP to access this server
resource Server_Name_AllowClientIP 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = {
  parent: Server_Name_resource
  name: 'AllowClientIP'
  properties: {
    endIpAddress: clientIP
    startIpAddress: clientIP
  }
}

// Make the user an Azure AD administrator for the server, so that the user can connect with universal authentication
resource Server_Name_activeDirectory 'Microsoft.Sql/servers/administrators@2023-02-01-preview' = {
  parent: Server_Name_resource
  name: 'activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: userName
    sid: userObjectId
    }
}

//////////////////////////////////////////////////////////////////////////////
// Create the ContosoHR database using the DC-series hardware configuration //
//////////////////////////////////////////////////////////////////////////////

resource Database_Resource 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: Server_Name_resource
  name: 'ContosoHR'
  location: location
  tags: {}
  sku: {
    name: 'GP_Gen5_2'
    tier: 'GeneralPurpose'
  }
  properties: {
    preferredEnclaveType: 'VBS'
  }
}

///////////////////////////////////
// Configure the web application //
///////////////////////////////////
var sqlServerSuffix = environment().suffixes.sqlServerHostname
// Create an App Service plan
resource WebAppServicePlan_Resource 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${projectName}plan'
 location: location
 properties: {}
  sku: {
    name: 'B1'
  }
}

// Create the App Service
resource WebApp_Resource 'Microsoft.Web/sites@2022-09-01' = {
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
      value: 'Server=tcp:${Server_Name_resource.name}${sqlServerSuffix};Database=ContosoHR;Column Encryption Setting=Enabled; Attestation Protocol = None; Authentication=Active Directory Managed Identity'
      type: 'SQLAzure'
    }
  }
 }
  //Define AppSetting to fetch the correct project from the GitHub Repository
 resource AppSetting 'config' = {
  name: 'appsettings'
  properties: {
    PROJECT: 'samples/features/security/always-encrypted-with-secure-enclaves/source/ContosoHR/ContosoHR.csproj'
  }
 }
}

 // Deploy the application
resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = {
  parent: WebApp_Resource
  name: 'web'
  properties: {
    repoUrl: 'https://github.com/microsoft/sql-server-samples.git'
    branch: 'master'
    isManualIntegration: true
  }
  dependsOn: [
         Server_Name_resource
       ]
}

//////////////////////////////////////
// Create and configure a key vault //
//////////////////////////////////////

// Create a key vault and assign key permissions to the user, so that the user can manage the keys
resource KeyVault_Resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${projectName}vault'
  location: location
  tags: {}
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: userObjectId
        permissions: {
          keys: [
            'unwrapKey'
            'wrapKey'
            'verify'
            'sign'
            'get'
            'list'
            'create'
            'delete'
            'purge'
          ]
        }
      }
    ]
  }
}

// Assign key permissions to the web app
resource KeyVaultWebAppAccessPolicy_Resource 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: any('${KeyVault_Resource.name}/add')
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        // objectId: reference(resourceId('Microsoft.Web/sites', '${projectName}app'), '2020-12-01', 'Full').resourceId
        objectId: WebApp_Resource.identity.principalId
        permissions: {
          keys: [
            'unwrapKey'
            'verify'
            'get'
          ]
        }
      }
    ]
  }
}

// Create a key
resource Key_Resource 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  parent: KeyVault_Resource
  name: 'CMK'
  tags: {}
  properties: {
    attributes: {
      enabled: true
    }
    kty: 'RSA'
    keySize: 4096
  }
}
