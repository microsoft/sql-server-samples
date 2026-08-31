@description('Name for the Log Analytics workspace backing Application Insights.')
param workspaceName string

@description('Name for the Application Insights resource.')
param appInsightsName string

@description('Location for monitoring resources.')
param location string

@description('Tags to apply to resources.')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The name of the Log Analytics workspace.')
output workspaceName string = workspace.name

@description('The name of the Application Insights resource.')
output appInsightsName string = appInsights.name

@description('The Application Insights connection string.')
output connectionString string = appInsights.properties.ConnectionString
