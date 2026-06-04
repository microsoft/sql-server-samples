targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@minLength(1)
@maxLength(64)
@description('Name of the environment (used to generate unique resource names).')
param environmentName string

@description('Primary location for SQL and other resources.')
@metadata({
  azd: {
    type: 'location'
  }
})
param location string = 'eastasia'

@description('Location for the Connector Namespace. Preview regions: westcentralus, eastasia, centralus, northeurope.')
param connectorNamespaceLocation string = location

@description('Object ID of the deployer user. Used as Entra admin for SQL and for access policies.')
@metadata({
  azd: {
    type: 'principalId'
  }
})
param deployerPrincipalId string = deployer().objectId

@description('Login name (email) of the deployer user for SQL Entra admin.')
param deployerLoginName string

@description('Name of the SQL Database to create.')
param databaseName string = 'mcpdb'

@description('Optional public IP address to allow through the SQL firewall. The azd post-provision hook also configures this for local setup.')
param deployerIpAddress string = ''

@allowed([
  'SystemAssigned'
  'UserAssigned'
])
@description('Managed identity type for the Connector Namespace and hosted SQL MCP server.')
param connectorNamespaceIdentityType string

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var readableEnvironmentName = take(toLower(replace(replace(replace(environmentName, '_', '-'), '.', '-'), ' ', '-')), 40)
var resourceToken = take(toLower(uniqueString(subscription().id, environmentName, location)), 8)
var tags = { 'azd-env-name': environmentName }
var resourceGroupName = 'rg-${readableEnvironmentName}'
var sqlServerName = 'sql-${readableEnvironmentName}-${resourceToken}'
var connectorNamespaceName = 'cn-${readableEnvironmentName}-${resourceToken}'
var userAssignedIdentityName = 'id-${readableEnvironmentName}-${resourceToken}'
var logAnalyticsWorkspaceName = 'log-${readableEnvironmentName}-${resourceToken}'
var appInsightsName = 'appi-${readableEnvironmentName}-${resourceToken}'
var useUserAssignedIdentity = connectorNamespaceIdentityType == 'UserAssigned'

// Load the included DAB config and base64-encode it for the ARM API.
var dabConfigBase64 = base64(loadTextContent('../dab-config.json'))

// ---------------------------------------------------------------------------
// Resource Group
// ---------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Azure SQL Server + Database
// ---------------------------------------------------------------------------

module sql './modules/sql.bicep' = {
  scope: rg
  name: 'sql-${resourceToken}'
  params: {
    sqlServerName: sqlServerName
    databaseName: databaseName
    location: location
    tags: tags
    entraAdminObjectId: deployerPrincipalId
    entraAdminLogin: deployerLoginName
    deployerIpAddress: deployerIpAddress
  }
}

// ---------------------------------------------------------------------------
// Application Insights
// ---------------------------------------------------------------------------

module appInsights './modules/appInsights.bicep' = {
  scope: rg
  name: 'appi-${resourceToken}'
  params: {
    workspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    location: 'southcentralus' // TODO: revert to `location` after testing
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Optional user-assigned managed identity
// ---------------------------------------------------------------------------

module userAssignedIdentity './modules/userAssignedIdentity.bicep' = if (useUserAssignedIdentity) {
  scope: rg
  name: 'id-${resourceToken}'
  params: {
    name: userAssignedIdentityName
    location: location
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Connector Namespace
// ---------------------------------------------------------------------------

module connectorNamespace './modules/connectorNamespace.bicep' = {
  scope: rg
  name: 'cn-${resourceToken}'
  params: {
    name: connectorNamespaceName
    location: connectorNamespaceLocation
    tags: tags
    identityType: connectorNamespaceIdentityType
    userAssignedIdentityResourceId: useUserAssignedIdentity ? userAssignedIdentity.outputs.id : ''
  }
}

var managedIdentityClientId = useUserAssignedIdentity ? userAssignedIdentity.outputs.clientId : ''
var sqlIdentityName = useUserAssignedIdentity ? userAssignedIdentity.outputs.name : connectorNamespace.outputs.name
var sqlIdentityPrincipalId = useUserAssignedIdentity ? userAssignedIdentity.outputs.principalId : connectorNamespace.outputs.principalId
var dabConnectionString = useUserAssignedIdentity
  ? 'Server=${sql.outputs.sqlServerFqdn};Database=${databaseName};Authentication=Active Directory Managed Identity;User Id=${managedIdentityClientId};Encrypt=True;TrustServerCertificate=False;'
  : 'Server=${sql.outputs.sqlServerFqdn};Database=${databaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;'

// ---------------------------------------------------------------------------
// Hosted SQL MCP Server + Access Policy
// ---------------------------------------------------------------------------

module hostedMcpServer './modules/hostedMcpServer.bicep' = {
  scope: rg
  name: 'mcp-${resourceToken}'
  params: {
    connectorNamespaceName: connectorNamespaceName
    name: 'sql-mcp'
    deployerPrincipalId: deployerPrincipalId
    dabConfigBase64: dabConfigBase64
    sqlConnectionString: dabConnectionString
    applicationInsightsConnectionString: appInsights.outputs.connectionString
    managedIdentityClientId: managedIdentityClientId
  }
  dependsOn: [
    connectorNamespace
  ]
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

@description('The name of the resource group.')
output RESOURCE_GROUP_NAME string = rg.name

@description('The name of the SQL Server.')
output SQL_SERVER_NAME string = sql.outputs.sqlServerName

@description('The fully qualified domain name of the SQL Server.')
output SQL_SERVER_FQDN string = sql.outputs.sqlServerFqdn

@description('The name of the SQL Database.')
output SQL_DATABASE_NAME string = sql.outputs.databaseName

@description('The name of the Connector Namespace.')
output CONNECTOR_NAMESPACE_NAME string = connectorNamespace.outputs.name

@description('The principal ID of the Connector Namespace system-assigned managed identity. Empty when using user-assigned identity only.')
output CONNECTOR_NAMESPACE_PRINCIPAL_ID string = connectorNamespace.outputs.principalId

@description('The managed identity name granted access to Azure SQL.')
output SQL_IDENTITY_NAME string = sqlIdentityName

@description('The managed identity principal ID granted access to Azure SQL.')
output SQL_IDENTITY_PRINCIPAL_ID string = sqlIdentityPrincipalId

@description('The managed identity client ID used by the hosted MCP server. Empty when using system-assigned identity.')
output SQL_IDENTITY_CLIENT_ID string = managedIdentityClientId

@description('The name of the Application Insights resource.')
output APPLICATIONINSIGHTS_NAME string = appInsights.outputs.appInsightsName

@description('The name of the Log Analytics workspace backing Application Insights.')
output LOG_ANALYTICS_WORKSPACE_NAME string = appInsights.outputs.workspaceName

@description('Connection string for DAB config.')
output DAB_CONNECTION_STRING string = dabConnectionString

@description('MCP endpoint URL — point VS Code / MCP clients here.')
output MCP_ENDPOINT_URL string = hostedMcpServer.outputs.mcpEndpointUrl
