@description('Azure SQL Server name.')
param sqlServerName string

@description('Azure SQL Database name.')
param databaseName string

@description('Location for resources.')
param location string

@description('Tags to apply to resources.')
param tags object = {}

@description('Object ID of the Entra ID admin for the SQL Server.')
param entraAdminObjectId string

@description('Login name of the Entra ID admin (email or display name).')
param entraAdminLogin string

@description('Tenant ID for Entra ID authentication.')
param tenantId string = tenant().tenantId

@description('Public IP of the deployer for SQL firewall rule (allows post-provision scripts to connect). Leave empty to skip.')
param deployerIpAddress string = ''

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: entraAdminLogin
      sid: entraAdminObjectId
      tenantId: tenantId
      principalType: 'User'
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Allow Azure services to access the SQL Server
resource firewallRuleAzure 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Allow the deployer's IP to connect for post-provision seeding/granting
resource firewallRuleDeployer 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (!empty(deployerIpAddress)) {
  parent: sqlServer
  name: 'AllowDeployerIp'
  properties: {
    startIpAddress: deployerIpAddress
    endIpAddress: deployerIpAddress
  }
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

@description('The fully qualified domain name of the SQL Server.')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('The name of the SQL Server.')
output sqlServerName string = sqlServer.name

@description('The name of the SQL Database.')
output databaseName string = database.name
