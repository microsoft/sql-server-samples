@sys.description('Name of the parent Connector Namespace.')
param connectorNamespaceName string

@sys.description('Name for the MCP server config (2-64 chars).')
@minLength(2)
@maxLength(64)
param name string

@sys.description('Description shown to MCP clients.')
param mcpServerDescription string = 'SQL MCP server bound to DAB config with managed identity.'

@sys.description('Object ID of the deployer user to grant MCP access.')
param deployerPrincipalId string

@sys.description('Tenant ID for access policies.')
param tenantId string = tenant().tenantId

@sys.description('Base64-encoded DAB configuration file content.')
param dabConfigBase64 string

@secure()
@sys.description('SQL connection string exposed to the hosted MCP server as SQL_CONNECTION_STRING.')
param sqlConnectionString string

@sys.description('Application Insights connection string exposed to the hosted MCP server as APPLICATIONINSIGHTS_CONNECTION_STRING.')
param applicationInsightsConnectionString string

@sys.description('Optional managed identity client ID exposed as AZURE_CLIENT_ID when using a user-assigned managed identity.')
param managedIdentityClientId string = ''

// Reference the existing Connector Namespace
resource connectorNamespace 'Microsoft.Web/connectorGateways@2026-05-01-preview' existing = {
  name: connectorNamespaceName
}

var hostedMcpConfiguration = union({
  configFile: dabConfigBase64
  SQL_CONNECTION_STRING: sqlConnectionString
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
}, empty(managedIdentityClientId) ? {} : {
  AZURE_CLIENT_ID: managedIdentityClientId
})

// Hosted MCP Server — runs the curated mcp-sql container image with DAB config
resource mcpServer 'Microsoft.Web/connectorGateways/mcpServerConfigs@2026-05-01-preview' = {
  parent: connectorNamespace
  name: name
  kind: 'HostedMcpServer'
  properties: {
    description: mcpServerDescription
    hostedMcpServer: {
      hostedMcpServerId: 'mcp-sql'
      configuration: hostedMcpConfiguration
    }
  }
}

// Grant the deployer access to invoke the MCP server tools.
// The access-policy name must equal the principal's objectId.
resource mcpAccessPolicy 'Microsoft.Web/connectorGateways/mcpServerConfigs/accessPolicies@2026-05-01-preview' = {
  parent: mcpServer
  name: deployerPrincipalId
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        objectId: deployerPrincipalId
        tenantId: tenantId
      }
    }
    principalType: 'User'
  }
}

@sys.description('Resource ID of the MCP server config.')
output id string = mcpServer.id

@sys.description('Name of the MCP server config.')
output mcpServerName string = mcpServer.name

@sys.description('MCP endpoint URL for clients to connect to.')
output mcpEndpointUrl string = mcpServer.properties.mcpEndpointUrl
