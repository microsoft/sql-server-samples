@description('Name for the user-assigned managed identity.')
param name string

@description('Location for the user-assigned managed identity.')
param location string

@description('Tags to apply to resources.')
param tags object = {}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

@description('The resource ID of the user-assigned managed identity.')
output id string = identity.id

@description('The name of the user-assigned managed identity.')
output name string = identity.name

@description('The client ID of the user-assigned managed identity.')
output clientId string = identity.properties.clientId

@description('The principal ID of the user-assigned managed identity.')
output principalId string = identity.properties.principalId
