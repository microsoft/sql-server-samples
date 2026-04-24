Import-Module "Az"
Import-Module "SqlServer"

######################################################################
# Prompt the user to enter the values of deployment parameters
######################################################################

$projectName = Read-Host -Prompt "Enter a project name that is used to generate resource names"
$subscriptionId = Read-Host -Prompt "Enter your subscription id"
$location = Read-Host -Prompt "Enter a region where you want to deploy the demo environment"
$sqlAdminUserName = Read-Host -Prompt "Enter the username of the Azure SQL database server administrator for SQL authentication"
$sqlAdminPasswordSecureString = Read-Host -Prompt "Enter the password of the Azure SQL database server administrator for SQL authentication" -AsSecureString
$Secure_String_Pwd = ConvertTo-SecureString $sqlAdminPasswordSecureString -AsPlainText -Force
$sqlAdminPassword = (New-Object PSCredential "user",$sqlAdminPasswordSecureString).GetNetworkCredential().Password
$clientIP = (Invoke-WebRequest http://ipinfo.io/ip).Content.Trim()
$bicepFile = "azuredeploy.bicep"
$projectName = $projectName.ToLower()

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

New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $bicepFile `
  -projectName $projectName `
  -userObjectId $userObjectId `
  -userName $userName `
  -sqlAdminUserName $sqlAdminUserName `
  -sqlAdminPassword $Secure_String_Pwd `
  -clientIP $clientIP

######################################################################
# Populate the database with data
######################################################################

$serverName = "${projectName}server.database.windows.net"
$databaseName = "ContosoHR"
$queryFile = "PopulateDatabase.sql"
$query = Get-Content -path $queryFile -Raw
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$serverName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

######################################################################
# Configure an extended event session to intercept application queries
######################################################################

$queryFile = "CreateXESession.sql"
$query = Get-Content -path $queryFile -Raw
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$serverName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

######################################################################
# Grant the web application access to the database
######################################################################

# Create a shadow principal, representing the application, in the database
$appName = "${projectName}app"
$query = "CREATE USER [$appName] FROM EXTERNAL PROVIDER;"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$ServerName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application read access to the database.
$query = "EXEC sp_addrolemember 'db_datareader', '$appName';"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$serverName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application write access to the database.
$query = "EXEC sp_addrolemember 'db_datawriter', '$appName';"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$serverName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application access to the key metadata database.
$query = "GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$serverName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

# Grant the application access to the key metadata database.
$query = "GRANT VIEW ANY COLUMN ENCRYPTION KEY DEFINITION TO [$appName];"
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "tcp:$serverName" -Database $databaseName -AccessToken $accessToken -QueryTimeout 30 -Query $query

######################################################################
# Configure key metadata in the database
######################################################################

# Get the column master key from Azure Key Vault
$keyVaultName = "${projectName}vault"
$keyName = "CMK"
$key = Get-AzKeyVaultKey -VaultName $keyVaultName -Name $keyName

# Connect to the database using the SqlServer PowerShell module
$connStr = "Data Source=tcp:$serverName;Initial Catalog=$databaseName;User ID=$sqlAdminUserName;Password=$sqlAdminPasswordSecureString"
$database = Get-SqlDatabase -ConnectionString $connStr

# Sign in to Azure with your email address using the SqlServer PowerShell module
Add-SqlAzureAuthenticationContext -Interactive

# Create a column master key metadata object in the database for the key in Azure Key Vault
$cmkName = "CMK1"
$cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $key.Key.Kid -AllowEnclaveComputations
New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings

# Create a column encryption key and its metadata object in the database
$cekName = "CEK1"
New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName

######################################################################
# Encrypt database columns
######################################################################

$encryptedColumnSettings = @()
$encryptedColumnSettings += New-SqlColumnEncryptionSettings -ColumnName "dbo.Employees.SSN" -EncryptionType "Randomized" -EncryptionKey $cekName
$encryptedColumnSettings += New-SqlColumnEncryptionSettings -ColumnName "dbo.Employees.Salary" -EncryptionType "Randomized" -EncryptionKey $cekName
Set-SqlColumnEncryption -ColumnEncryptionSettings $encryptedColumnSettings -InputObject $database -LogFileDirectory .

######################################################################
# Configure the attestation policy
######################################################################

$resourceGroupName = "${projectName}"
$attestationProviderName = "${projectName}attestation"
$policyFile = "AttestationPolicy.txt"
$teeType = "SgxEnclave"
$policyFormat = "Text"
$policy=Get-Content -path $policyFile -Raw
Set-AzAttestationPolicy -Name $attestationProviderName -ResourceGroupName $resourceGroupName -Tee $teeType -Policy $policy -PolicyFormat  $policyFormat

# Get the attestation URL
$attestationProvider = Get-AzAttestationProvider -Name $attestationProviderName -ResourceGroupName $resourceGroupName
$attestationUrl = $attestationProvider.AttestUri

######################################################################
# Print parameters for the demo
######################################################################

$app = Get-AzWebApp -Name $appName -ResourceGroupName $resourceGroupName
Write-Host -ForegroundColor "green" "Resource group name: $resourceGroupName"
Write-Host -ForegroundColor "green" "Database server name: $serverName"
Write-Host -ForegroundColor "green" "Database name: $databaseName"
Write-Host -ForegroundColor "green" "Attestation URL: $attestationUrl"
Write-Host -ForegroundColor "green" "Application URL: https://$($app.HostNames[0].ToString())"
