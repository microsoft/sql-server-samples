Import-Module "Az" -MinimumVersion "7.2.1"
Import-Module "SqlServer" -MinimumVersion "21.1.18256"

######################################################################
# Prompt the user to enter the values of deployment parameters
######################################################################

$projectName = Read-Host -Prompt "Enter a project name that is used to generate resource names"
$subscriptionId = Read-Host -Prompt "Enter your subscription id"
$location = Read-Host -Prompt "Enter a region where you want to deploy the demo environment"
$sqlAdminUserName = Read-Host -Prompt "Enter the username of the Azure SQL database server administrator for SQL authentication"
$sqlAdminPasswordSecureString = Read-Host -Prompt "Enter the password of the Azure SQL database server administrator for SQL authentication" -AsSecureString

$sqlAdminPassword = (New-Object PSCredential "user",$sqlAdminPasswordSecureString).GetNetworkCredential().Password
$clientIP = (Invoke-WebRequest ifconfig.me/ip).Content.Trim()
$bicepFile = "azuredeploy.bicep"
$projectName = $projectName.ToLower()
$location = $location.ToLower()

######################################################################
# Sign in to Azure
######################################################################

Connect-AzAccount
$context = Set-AzContext -Subscription $subscriptionId
$userName = $context.Account.Id
$userObjectId = $(Get-AzADUser -UserPrincipalName $userName).Id

######################################################################
# Create a resource group
######################################################################
$resourceGroupName = "${projectName}"
New-AzResourceGroup -Name $resourceGroupName -Location $location

######################################################################
# Deploy the resources for the demo environment
######################################################################

$deployment=New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $bicepFile `
  -projectName $projectName `
  -userObjectId $userObjectId `
  -userName $userName `
  -sqlAdminUserName $sqlAdminUserName `
  -sqlAdminPassword $sqlAdminPassword `
  -clientIP $clientIP

$fullServerName = $deployment.Outputs.servername.Value
$databaseName = $deployment.Outputs.databaseName.Value
$appName = $deployment.Outputs.appname.Value

######################################################################
# Create the database schema and populate it with data
######################################################################

# Create the databse schema
$queryFile = "CreateDatabaseSchema.sql"
$query = Get-Content -path $queryFile -Raw
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Populate the database
$queryFile = "PopulateDatabase.sql"
$query = Get-Content -path $queryFile -Raw
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

######################################################################
# Grant the web application access to the database
######################################################################

# Create a shadow principal, representing the application, in the database
$query = "CREATE USER [$appName] FROM EXTERNAL PROVIDER;"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application access to the database.
$query = "ALTER ROLE db_datareader ADD MEMBER [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application access to the database.
$query = "ALTER ROLE db_datawriter ADD MEMBER [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application access to ledger content.
$query = "GRANT VIEW LEDGER CONTENT TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application access to stored procedures.
$query = "GRANT EXECUTE ON [dbo].[VerifyLedger] TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

$query = "GRANT EXECUTE ON [dbo].[GetEmployeeLedgerEntries] TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

$query = "GRANT EXECUTE ON [dbo].[GetLedgerVerifications] TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

$query = "GRANT EXECUTE ON [dbo].[GetAuditEvents] TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$fullServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

######################################################################
# Print parameters for the demo
######################################################################

$app = Get-AzWebApp -Name $appName -ResourceGroupName $resourceGroupName
Write-Host -ForegroundColor "green" "Resource group name: $resourceGroupName"
Write-Host -ForegroundColor "green" "Database server name: $fullServerName"
Write-Host -ForegroundColor "green" "Database name: $databaseName"
Write-Host -ForegroundColor "green" "Application URL: https://$($app.HostNames[0].ToString())"