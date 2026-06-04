@description('Name for the Connector Namespace.')
param name string

@description('Location for the Connector Namespace. During preview, only select regions are supported: westcentralus, eastasia, centralus, northeurope.')
param location string

@description('Tags to apply to resources.')
param tags object = {}

@allowed([
  'SystemAssigned'
  'UserAssigned'
])
@description('Managed identity type for the Connector Namespace.')
param identityType string = 'SystemAssigned'

@description('Resource ID of the user-assigned managed identity to attach when identityType is UserAssigned.')
param userAssignedIdentityResourceId string = ''

var identityBlock = identityType == 'UserAssigned' ? {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userAssignedIdentityResourceId}': {}
  }
} : {
  type: 'SystemAssigned'
}

resource connectorNamespace 'Microsoft.Web/connectorGateways@2026-05-01-preview' = {
  name: name
  location: location
  tags: tags
  identity: identityBlock
  properties: {}
}

@description('The resource ID of the Connector Namespace.')
output resourceId string = connectorNamespace.id

@description('The name of the Connector Namespace.')
output name string = connectorNamespace.name

@description('The principal ID of the system-assigned managed identity. Empty when using user-assigned identity only.')
output principalId string = identityType == 'SystemAssigned' ? connectorNamespace.identity.principalId : ''
