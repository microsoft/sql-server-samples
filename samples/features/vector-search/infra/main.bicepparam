using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'development')
param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus2')
param sqlLocation = readEnvironmentVariable('AZURE_SQL_LOCATION', 'westus2')
param deploymentUserPrincipalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param clientIpAddress = readEnvironmentVariable('AZURE_CLIENT_IP', '')
