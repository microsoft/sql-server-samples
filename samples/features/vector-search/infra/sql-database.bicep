metadata description = 'Create Azure SQL Server and Database with Azure AD-only authentication.'

param serverName string
param databaseName string
param location string = resourceGroup().location
param tags object = {}

@description('Object ID of the Microsoft Entra user/group to set as SQL Server administrator. Required — deployment fails if empty.')
@minLength(36)
@maxLength(36)
param aadAdminObjectId string

@description('Principal ID of the managed identity for role assignments.')
param managedIdentityPrincipalId string = ''

@description('Client IP address for local development access. Set by azd during deployment.')
param clientIpAddress string = ''

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    // Azure AD-only authentication — no SQL auth passwords
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: 'aad-admin'
      sid: aadAdminObjectId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: true
    }
    minimalTlsVersion: '1.2'
  }
}

// Allow Azure services (including Azure OpenAI, managed identities) to connect
resource firewallAllowAzure 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Allow the deploying user's IP for local development
resource firewallAllowClient 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = if (!empty(clientIpAddress)) {
  parent: sqlServer
  name: 'AllowClientIP'
  properties: {
    startIpAddress: clientIpAddress
    endIpAddress: clientIpAddress
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
}

// SQL DB Contributor role for managed identity (database-level management access)
// Data plane access (query/insert) requires T-SQL GRANT after deployment.
var sqlDbContributorRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
)

resource managedIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(sqlServer.id, managedIdentityPrincipalId, sqlDbContributorRole)
  scope: sqlServer
  properties: {
    roleDefinitionId: sqlDbContributorRole
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
output serverName string = sqlServer.name
output databaseName string = sqlDatabase.name
