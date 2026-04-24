#Requires -Modules Az.ResourceGraph, Az.ConnectedMachine, Az.Accounts
# This script returns a report of the instances that should return SQL Reclass from the Azure Arc servers perspective
# It also returns all the extension status from Arc Servers that has mssqldiscovered to true

#region Sample queries

# Get SQL Azure Arc Servers
$queryArcSQLServers = @"
resources
| where type =~ 'microsoft.hybridcompute/machines'
| where properties.detectedProperties.mssqldiscovered == "true"
"@

# Get SQL Instances
$queryArcSQLServerinstances = @'
resources
| where ['type'] == "microsoft.azurearcdata/sqlserverinstances"
| project containerResourceId = properties.containerResourceId, instanceName = properties.instanceName, edition = properties.edition, version = properties.version, licenseType = properties.licenseType
'@
#Get SQL Instances
$queryArcServerextensions = @"
resources
| where type == 'microsoft.hybridcompute/machines/extensions' 
| where properties.type == "WindowsAgent.SqlServer"
"@
#endregion


#region Report of servers generating SQL Reclass
# The following query returns all the SQL Enterprise and Standard Instances, whose Azure Arc server exists and it is not in Expired State
# The query returns the created time, version, licensetype and vcores
$queryglobal = @"
resources
| where type in ('microsoft.hybridcompute/machines')
| extend Status = properties.status, id = tolower(id), AzureArcServerName = name
| where properties.status != "Expired"
| join kind = fullouter
(resources
| where type == 'microsoft.hybridcompute/machines/extensions' 
| where properties.type == "WindowsAgent.SqlServer"
| project id=tolower(id),AzureArcServerid = tolower(tostring(split(id,'/extensions/',0)[0])), ExVersion = properties.typeHandlerVersion, provisioningState = tostring(properties.provisioningState)
| order by provisioningState) on `$left.['id'] == `$right.AzureArcServerid
| join kind=inner (
resources
| where type =~ "Microsoft.AzureArcData/sqlServerInstances"
| extend edition = tostring(properties.edition)
| where edition in ('Standard','Enterprise')
| extend AzureArcServerid = tolower(tostring(properties.containerResourceId))
| extend SQLInstanceName = name
| extend createdAt = format_datetime(todatetime(systemData.createdAt), 'yyyy-MM-dd hh:mm:ss')
| extend version = tostring(properties.version)
| extend licenseType = tostring(properties.licenseType)
| extend vcores = toint(properties.vCore)) on AzureArcServerid
| where isnotempty(['id'])
| project createdAt,subscriptionId,resourceGroup,AzureArcServerName,Status,SQLInstanceName,version,edition,vcores,licenseType,ExVersion,provisioningState
"@

#KQL Global Query results
Write-Host "Querying servers that are generating SQL Reclass .. `n" -ForegroundColor Green
$ResultsGlobal = Search-AzGraph -Query $queryglobal -First 1000


# View LicenseType property directly from Azure Arc Extension and merge the data in a single table

Write-Host "Querying extension using powershell. This might take a while .. `n" -ForegroundColor Green
$ResultsGlobalGrouped = $ResultsGlobal | Group-Object -Property subscriptionid
$results = foreach ($group in $ResultsGlobalGrouped) {
    #Get-AzSubscription -SubscriptionId $group.Name -WarningAction SilentlyContinue
    $Subscription = Select-AzSubscription -SubscriptionId $group.Name -WarningAction SilentlyContinue
    Write-Host "Getting SQL extension information from Subscription:" -ForegroundColor Green
    Write-Host "$($Subscription.Subscription.Name) $($Subscription.Subscription.id)" -ForegroundColor Yellow
    foreach ($arcobject in $group.Group ) {
        $machinename = $arcobject.AzureArcServerName
        $ResourceGroupName = $arcobject.resourceGroup
        $licensetype = Get-AzConnectedMachineExtension -MachineName $machinename -ResourceGroupName $ResourceGroupName -Name WindowsAgent.SqlServer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty setting | ConvertFrom-Json | Select-Object -ExpandProperty LicenseType -ErrorAction SilentlyContinue
        $properties = [ordered]@{
            createdAt          = $arcobject.createdAt          
            subscriptionId     = $arcobject.subscriptionId     
            resourceGroup      = $arcobject.resourceGroup      
            AzureArcServerName = $arcobject.AzureArcServerName
            Status             = $arcobject.Status 
            SQLInstanceName    = $arcobject.SQLInstanceName    
            version            = $arcobject.version            
            edition            = $arcobject.edition            
            vcores             = $arcobject.vcores             
            licenseTypeinGraph = $arcobject.licenseType   
            licenseTypeInExt   = $licensetype                   
            ExVersion          = $arcobject.ExVersion          
            provisioningState  = $arcobject.provisioningState  
                    
        }
        New-Object -TypeName psobject -Property $properties 
       
    } 
}
# Variable $results contains all the info

# The following exports in a CSV file the servers that are effectively generating ACR (2008 is not suported)
$global:ArcSQLServerinstanceswithReclass = $results | where version -notlike *2008*
$ArcSQLServerinstanceswithReclass | Export-Csv -Path .\ArcSQLServerinstanceswithReclass.csv -Force -NoTypeInformation
Write-Host "Results where exported to file 'ArcSQLServerinstanceswithReclass.csv' in the local folder" -ForegroundColor Green
#endregion

###############################

#region Report of SQL extension Status

# The following query returns all the SQL extensions from servers that has mssqldiscovered set to True
# The query returns the Arc Server with its subscription, resource group, status, extension version and provisioning state

$queryExtensionSatus = @"
resources
| where type =~ 'microsoft.hybridcompute/machines'
| where properties.detectedProperties.mssqldiscovered == "true"
| extend id = tolower(id), ResourceGroup = split (id,'/',4)[0], Status = properties.status
| join kind = inner (resources
| where type == 'microsoft.hybridcompute/machines/extensions' 
| where properties.type == "WindowsAgent.SqlServer"
| extend provisioningState = tostring(properties.provisioningState), ExVersion = properties.typeHandlerVersion
| extend AzureArcServerid = tolower(tostring(split(id,'/extensions/',0)[0]))) on `$left.id == `$right.AzureArcServerid
| project subscriptionId,ResourceGroup,name,Status,ExVersion,provisioningState
| order by ['provisioningState'] asc
"@

Write-Host "`nQuerying status of the SQL Extensions in azure Arc servers .. `n" -ForegroundColor Green
$global:SQLExtensionStatus = Search-AzGraph -Query $queryExtensionSatus -First 1000

# The following exports in a CSV file the status of the SQL extension in the Azure Arc Servers
$SQLExtensionStatus | Export-Csv -Path .\SQLExtensionStatus.csv -Force -NoTypeInformation
Write-Host "Results where exported to file 'SQLExtensionStatus.csv' in the local folder" -ForegroundColor Green

# region samples
# Servers with the license not set to Paid:
#$ArcSQLServerinstanceswithReclass | where licenseTypeinGraph -ne "Paid" | Select-Object subscriptionId,resourceGroup,AzureArcServerName,Status -Unique

#Extensionstofix
#$ExtensionStatus | Out-GridView

#endregion