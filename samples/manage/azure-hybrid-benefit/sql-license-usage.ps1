#
# This script provides a simple solution to analyze and track the consolidated utilization of SQL Server licenses 
# by all of the SQL resources in a specific subscription or the entire the account. By default, the script scans 
# all subscriptions the user account has access. Alternatively, you can specify a single subscription or a .CSV file 
# with a list of subscription. The usage report includes the following information for each scanned subscription.
#
# The following resources are in scope for the license utilization analysis:
# - Azure SQL databases (vCore-based purchasing model only) 
# - Azure SQL elastic pools (vCore-based purchasing model only)
# - Azure SQL managed instances
# - Azure SQL instance pools
# - Azure Data Factory SSIS integration runtimes
# - SQL Servers in Azure virtual machines 
# - SQL Servers in Azure virtual machines hosted in Azure dedicated host
#
# NOTE: The script does not calculate usage for Azure SQL resources that use the DTU-based purchasing model
#
# The script accepts the following command line parameters:
# 
# -SubId [subscription_id] | [csv_file_name]        (Accepts a .csv file with the list of subscriptions)
# -Server [protocol:]server[instance_name][,port]   (Required to save data to the database)
# -Database [database_name]                         (Required to save data to the database)
# -Cred [credential_object]                         (Required to save data to the database)
# -FilePath [csv_file_name]                         (Required to save data in a .csv format. Ignored if database parameters are specified)
# -UseInRunbook [True] | [False]                    (Required when executed as a Runbook)
# -ShowUnregistered [True] | [False]                (Optional. If specified, checks every VM if SQL server is installed)
# 

param (
    [Parameter (Mandatory= $false)] 
    [string] $SubId, 
    [Parameter (Mandatory= $false)]
    [string] $Server, 
    [Parameter (Mandatory= $false)]
    [PSCredential] $Cred, 
    [Parameter (Mandatory= $false)]
    [string] $Database, 
    [Parameter (Mandatory= $false)]
    [string] $FilePath, 
    [Parameter (Mandatory= $false)]
    [bool] $UseInRunbook = $false, 
    [Parameter (Mandatory= $false)]
    [bool] $ShowEC = $false,
    [Parameter (Mandatory= $false)]
    [bool] $ShowUnregistered = $false

)

function CheckModule ($m) {

    # This function ensures that the specified module is imported into the session
    # If module is already imported - do nothing

    if (!(Get-Module | Where-Object {$_.Name -eq $m})) {
         # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
            Import-Module $m 
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m
            }
            else {

                # If module is not imported, not available and not in online gallery then abort
                write-host "Module $m not imported, not available and not in online gallery, exiting."
                EXIT 1
            }
        }
    }
}

function GetVCores {
    # This function translates each VM or Host sku type and name into vCores
    
     [CmdletBinding()]
     param (
         [Parameter(Mandatory)]
         [string]$type,
         [Parameter(Mandatory)]
         [string]$name
     )
     
     if ($global:VM_SKUs.Count -eq 0){
         $global:VM_SKUs = Get-AzComputeResourceSku  "westus" | where-object {$_.ResourceType -in 'virtualMachines','hostGroups/hosts'}
     }
     # Select first size and get the VCPus available
     $size_info = $global:VM_SKUs | Where-Object {$_.ResourceType.Contains($type) -and ($_.Name -eq $name)} | Select-Object -First 1
                         
     # Save the VCPU count
     switch ($type) {
         "hosts" {$vcpu = $size_info.Capabilities | Where-Object {$_.name -eq "Cores"} }
         "virtualMachines" {$vcpu = $size_info.Capabilities | Where-Object {$_.name -eq "vCPUsAvailable"} }
     }
     
     if ($vcpu){
         return $vcpu.Value
     }
     else {
         return 0
     }      
 }
function AddVCores {
    # This function breaks down vCores into the $subtotal columns
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$Tier,
        [Parameter(Mandatory=$false)]
        [string]$LicenseType,
        [Parameter(Mandatory)]
        $CoreCount
    )
    #write-host $Tier "," $LicenseType "," $CoreCount
    switch ($Tier) {
        "BusinessCritical" {
            switch ($LicenseType) {
                "BasePrice" {$script:subtotal.ahb_ent += $CoreCount}
                "LicenseIncluded" {$script:subtotal.payg_ent += $CoreCount} 
                default {$script:subtotal.payg_ent += $CoreCount} 
            }
        }
        "GeneralPurpose" {
            switch ($LicenseType) {
                "BasePrice" {$script:subtotal.ahb_std += $CoreCount}
                "LicenseIncluded" {$script:subtotal.payg_std += $CoreCount} 
                default {$script:subtotal.payg_std += $CoreCount}
            }
        }
        "Hyperscale" {
            switch ($LicenseType) {
                "BasePrice" {$script:subtotal.ahb_std += $CoreCount}
                "LicenseIncluded" {$script:subtotal.payg_std += $CoreCount} 
                default {$script:subtotal.payg_std += $CoreCount} 
            }
        }
        "Enterprise" {
            switch ($LicenseType) {
                "BasePrice" {$script:subtotal.ahb_ent += $CoreCount}
                "LicenseIncluded" {$script:subtotal.payg_ent += $CoreCount} 
                "AHUB" {$script:subtotal.ahb_ent += $CoreCount}
                "DR" {$script:subtotal.hadr_ent += $CoreCount}
                "PAYG" {$script:subtotal.payg_ent += $CoreCount} 
                default {$script:subtotal.payg_ent += $CoreCount} 
            }
        }
        "Standard" {
            switch ($LicenseType) {
                "BasePrice" {$script:subtotal.ahb_std += $CoreCount}
                "LicenseIncluded" {$script:subtotal.payg_std += $CoreCount} 
                "AHUB" {$script:subtotal.ahb_std += $CoreCount}
                "DR" {$script:subtotal.hadr_std += $CoreCount}
                "PAYG" {$script:subtotal.payg_std += $CoreCount} 
                default {$script:subtotal.payg_std += $CoreCount}
            }
        }
        "Developer" {            
            $script:subtotal.developer += $CoreCount
        }
        "Express" {
            $script:subtotal.express += $CoreCount
        }
        default {
            $script:subtotal.unknown_tier += $CoreCount
        }
    }   
}

function DiscoveryOnWindows {
    
# This script checks if SQL Server is installed on Windows
    
    [bool] $SqlInstalled = $false 
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
    if (Test-Path $regPath) {
        $inst = (get-itemproperty $regPath).InstalledInstances
        $SqlInstalled = ($inst.Count -gt 0)
    }
    Write-Output $SqlInstalled
}

#
# This script checks if SQL Server is installed on Linux
# 
#    
$DiscoveryOnLinux =
    'if ! systemctl is-active --quiet mssql-server.service; then 
    echo "False" 
    exit 
    else 
        echo "True" 
    fi'


#The following block is required for runbooks only
if ($UseInRunbook){

    # Ensures you do not inherit an AzContext in your runbook
    Disable-AzContextAutosave –Scope Process

    $connection = Get-AutomationConnection -Name AzureRunAsConnection

    # Wrap authentication in retry logic for transient network failures
    $logonAttempt = 0
    while(!($connectionResult) -and ($logonAttempt -le 10))
    {
        $LogonAttempt++
        # Logging in to Azure...
        $connectionResult = Connect-AzAccount `
                            -ServicePrincipal `
                            -Tenant $connection.TenantID `
                            -ApplicationId $connection.ApplicationID `
                            -CertificateThumbprint $connection.CertificateThumbprint

        Start-Sleep -Seconds 5
    }
}else{
    # Ensure that the required modules are imported
    # In Runbooks these modules must be added to the automation account manually

    $requiredModules = @(
        "Az.Accounts",
        "Az.Compute",
        "Az.DataFactory",
        "Az.Resources",
        "Az.Sql",
        "Az.SqlVirtualMachine"
    )
    $requiredModules | Foreach-Object {CheckModule $_}
}

# Save the function definitions to run in parallel loops
$GetVCoresDef = $function:GetVCores.ToString()
$AddVCoresDef = $function:AddVCores.ToString()

# Create a script file with the SQL server discovery logic
New-Item  -ItemType file -path DiscoverSql.ps1 -value $function:DiscoveryOnWindows.ToString() -Force | Out-Null
New-Item  -ItemType file -path DiscoverSql.sh -value $DiscoveryOnLinux -Force | Out-Null

# Subscriptions to scan


if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne $null){
    $subscriptions = [PSCustomObject]@{SubscriptionId = $SubId} | Get-AzSubscription 
}else{
    $subscriptions = Get-AzSubscription
}

[bool] $useDatabase = $PSBoundParameters.ContainsKey("Server") -and $PSBoundParameters.ContainsKey("Cred") -and $PSBoundParameters.ContainsKey("Database")

# Initialize tables and arrays 

if ($useDatabase){
    
    #Database setup

    #$cred = New-Object System.Management.Automation.PSCredential($Username,$Password)
    
    [String] $tableName = "Usage-per-subscription"
    [String] $testSQL = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
                    WHERE TABLE_SCHEMA = 'dbo' 
                    AND  TABLE_NAME = '$tableName'"
    [String] $createSQL = "CREATE TABLE [dbo].[$tableName](
                    [Date] [date] NOT NULL,
                    [Time] [time](7) NOT NULL,
                    [SubscriptionName] [nvarchar](50) NOT NULL,
                    [SubscriptionID] [nvarchar](50) NOT NULL,
                    [AHB_EC] [int] NULL,
                    [PAYG_EC] [int] NULL,
                    [AHB_STD_vCores] [int] NULL,
                    [AHB_ENT_vCores] [int] NULL,
                    [PAYG_STD_vCores] [int] NULL,
                    [PAYG_ENT_vCores] [int] NULL,
                    [HADR_STD_vCores] [int] NULL,
                    [HADR_ENT_vCores] [int] NULL,
                    [Developer_vCores] [int] NULL,
                    [Express_vCores] [int] NULL,
                    [Unregistered_vCores] [int] NULL,
                    [Unknown_vCores] [int] NULL)"
    [String] $insertSQL = "INSERT INTO [dbo].[$tableName](
                    [Date],
                    [Time],
                    [SubscriptionName],
                    [SubscriptionID],
                    [AHB_EC],
                    [PAYG_EC],
                    [AHB_STD_vCores],
                    [AHB_ENT_vCores],
                    [PAYG_STD_vCores],
                    [PAYG_ENT_vCores],
                    [HADR_STD_vCores],
                    [HADR_ENT_vCores],
                    [Developer_vCores],
                    [Express_vCores],
                    [Unregistered_vCores],
                    [Unknown_vCores]) 
                    VALUES 
                    ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}' )"        
    $propertiesToSplat = @{
        Database = $Database
        ServerInstance = $Server
        User = $Cred.Username
        Password = $Cred.GetNetworkCredential().Password
        Query = $testSQL
    }
       
    # Create table if does not exist
    if ((Invoke-SQLCmd @propertiesToSplat).Column1 -eq 0) {
        $propertiesToSplat.Query = $createSQL
        Invoke-SQLCmd @propertiesToSplat
    }

}else{

    #File setup 
    if (!$PSBoundParameters.ContainsKey("FilePath")) {
        $FilePath = '.\sql-license-usage.csv'
    }

    [System.Collections.ArrayList]$usageTable = @()
    $usageTable += ,(@("Date", "Time", "Subscription Name", "Subscription ID", "AHB ECs", "PAYG ECs", "AHB Std vCores", "AHB Ent vCores", "PAYG Std vCores", "PAYG Ent vCores", "HADR Std vCores", "HADR Ent vCores", "Developer vCores", "Express vCores", "Unregistered vCores", "Unknown vCores"))
}

$global:VM_SKUs = @{} # To hold the VM SKU table for future use
$subtotal = [pscustomobject]@{ahb_std=0; ahb_ent=0; payg_std=0; payg_ent=0; hadr_std=0; hadr_ent=0; developer=0; express=0; unreg_sqlvm=0; unknown_tier=0}
#$total = [pscustomobject]@{}
#$subtotal.psobject.properties.name | Foreach-Object {$total | Add-Member -MemberType NoteProperty -Name $_ -Value 0}

Write-Host ([Environment]::NewLine + "-- Scanning subscriptions --")

# Calculate usage for each subscription 

foreach ($sub in $subscriptions){

    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id  
    }catch {
        write-host "Invalid subscription: " $sub.Id
        {continue}
    }

    # Reset the subtotals     
    $subtotal.psobject.properties.name | Foreach-object {$subtotal.$_ = 0}
        
    # Get all resource groups in the subscription
    $rgs = Get-AzResourceGroup
    
    # Get all logical servers
    $servers = Get-AzSqlServer 

    # Scan all vCore-based SQL database resources in the subscription
    $servers | Get-AzSqlDatabase |  Where-Object { $_.SkuName -ne "ElasticPool" -and $_.Edition -in "GeneralPurpose", "BusinessCritical", "Hyperscale"} | Foreach-Object {
        AddVCores -Tier $_.Edition -LicenseType $_.LicenseType -CoreCount $_.Capacity
    }
    [system.gc]::Collect()

    # Scan all vcOre-based SQL elastic pool resources in the subscription
    $servers | Get-AzSqlElasticPool | Where-Object { $_.Edition -in "GeneralPurpose", "BusinessCritical", "Hyperscale"} | Foreach-Object {
        AddVCores -Tier $_.Edition -LicenseType $_.LicenseType -CoreCount $_.Capacity
    }
    [system.gc]::Collect()

    # Scan all SQL managed instance resources in the subscription
    Get-AzSqlInstance | Where-Object { $_.InstancePoolName -eq $null} | Foreach-Object {
        AddVCores -Tier $_.Sku.Tier -LicenseType $_.LicenseType -CoreCount $_.VCores
    }
    [system.gc]::Collect()
     
    # Scan all instance pool resources in the subscription
    Get-AzSqlInstancePool | Foreach-Object {
        AddVCores -Tier $_.Edition -LicenseType $_.LicenseType -CoreCount $_.VCores
    }
    [system.gc]::Collect()

    # Scan all SSIS imtegration runtime resources in the subscription
    $rgs | Get-AzDataFactoryV2 | Get-AzDataFactoryV2IntegrationRuntime |  Where-Object { $_.State -eq "Started" -and $_.Nodesize -ne $null } | Foreach-Object {
        $vCores = GetVCores -type "virtualMachines" -name $_.NodeSize
        AddVCores -Tier $_.Edition -LicenseType $_.LicenseType -CoreCount $vCores      
    }
    [system.gc]::Collect()

    # Scan all VMs with SQL server installed using a parallel loop (up to 10 at a time). For that reason function AddVCores is not used 
    # NOTE: ForEach-Object -Parallel is not supported in Runbooks (requires PS v7.1)
    if ($PSVersionTable.PSVersion.Major -ge 7){
        $vms = Get-AzVM -Status | Where-Object { $_.powerstate -eq 'VM running' } | ForEach-Object -ThrottleLimit 10 -Parallel {
            $function:GetVCores = $using:GetVCoresDef          
            $vCores = GetVCores -type 'virtualMachines' -name $_.HardwareProfile.VmSize
            $sql_vm = Get-AzSqlVm -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Ignore
            
            if ($sql_vm) {
                switch ($sql_vm.Sku) {
                    "Enterprise" {
                        switch ($sql_vm.LicenseType) {
                            "AHUB" {$($using:subtotal).ahb_ent += $vCores}
                            "DR" {$($using:subtotal).hadr_ent += $vCores}
                            "PAYG" {$($using:subtotal).payg_ent += $vCores} 
                            default {$($using:subtotal).payg_ent += $vCores} 
                        }
                    }
                    "Standard" {
                        switch ($sql_vm.LicenseType) {
                            "AHUB" {$($using:subtotal).ahb_std += $vCores}
                            "DR" {$($using:subtotal).hadr_std += $vCores}
                            "PAYG" {$($using:subtotal).payg_std += $vCores} 
                            default {$($using:subtotal).payg_std += $vCores}
                        }
                    }
                    "Developer" {                        
                        $($using:subtotal).developer += $vCores
                    }
                    "Express" {
                        $($using:subtotal).express += $vCores
                    }        
                }     
            }
            else {
                if ($($using:ShowUnregistered)){
                    if ($_.StorageProfile.OSDisk.OSType -eq "Windows"){            
                        $params =@{
                            ResourceGroupName = $_.ResourceGroupName
                            Name = $_.Name
                            CommandId = 'RunPowerShellScript'
                            ScriptPath = 'DiscoverSql.ps1'
                            ErrorAction = 'Stop'
                        } 
                    }
                    else {
                        $params =@{
                            ResourceGroupName = $_.ResourceGroupName
                            Name = $_.Name
                            CommandId = 'RunShellScript'
                            ScriptPath = 'DiscoverSql.sh'
                            ErrorAction = 'Stop'
                        }                       
                    }
                    try {                    
                        $out = Invoke-AzVMRunCommand @params            
                        if ($out.Value[0].Message.Contains('True')){                
                            $($using:subtotal).unreg_sqlvm += $vCores            
                        }                
                    }
                    catch {          
                        write-host $params.Name "No acceaa"
                    }
                }
            }
        }        
    }
    else {
        Get-AzVM -Status | Where-Object { $_.powerstate -eq 'VM running' } | ForEach-Object {
            $vCores = GetVCores -type 'virtualMachines' -name $_.HardwareProfile.VmSize
            $sql_vm = Get-AzSqlVm -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Ignore
            if ($sql_vm) {
                AddVCores -Tier $sql_vm.Sku -LicenseType $sql_vm.LicenseType -CoreCount $vCores                
            }
            else {
                if ($ShowUnregistered){
                    if ($_.StorageProfile.OSDisk.OSType -eq "Windows"){            
                        $params =@{
                            ResourceGroupName = $_.ResourceGroupName
                            Name = $_.Name
                            CommandId = 'RunPowerShellScript'
                            ScriptPath = 'DiscoverSql.ps1'
                            ErrorAction = 'Stop'
                        } 
                    }
                    else {
                        $params =@{
                            ResourceGroupName = $_.ResourceGroupName
                            Name = $_.Name
                            CommandId = 'RunShellScript'
                            ScriptPath = 'DiscoverSql.sh'
                            ErrorAction = 'Stop'
                        }                       
                    }try {
                        $out = Invoke-AzVMRunCommand @params            
                        if ($out.Value[0].Message.Contains('True')){                
                            $subtotal.unreg_sqlvm += $vCores            
                        }
                    }
                    catch {          
                        write-host $params.Name "No acceaa"
                    }
                }
            }
        }        
    }    
    [system.gc]::Collect()

    # Scan the VMs hosts in the subscription
    $host_groups = Get-AzHostGroup 

    # Get the dedicated host size, match it with the corresponding VCPU count and add to VCore count
    
    foreach ($host_group in $host_groups){
        
        $vm_hosts = $host_group | Select-Object -Property @{Name = 'HostGroupName'; Expression = {$_.Name}},@{Name = 'ResourceGroupName'; Expression = {$_.ResourceGroupName}} | Get-AzHost
    
        foreach ($vm_host in $vm_hosts){

            $token = (Get-AzAccessToken).Token
            $params = @{
                Uri         = "https://management.azure.com/subscriptions/" + $sub.Id + 
                            "/resourceGroups/" + $vm_host.ResourceGroupName.ToLower() + 
                            "/providers/Microsoft.Compute/hostGroups/" + $host_group.Name + 
                            "/hosts/" + $vm_host.Name + 
                            "/providers/Microsoft.SoftwarePlan/hybridUseBenefits/SQL_" + $host_group.Name + "_" + $vm_host.Name + "?api-version=2019-06-01-preview"
                Headers     = @{ 'Authorization' = "Bearer $token" }
                Method      = 'GET'
                ContentType = 'application/json'
            }
            
            try {
                $softwarePlan = Invoke-RestMethod @params
                if ($softwarePlan.Sku.Name -like "SQL*"){            
                    $subtotal.ahb_ent += (GetVCores -type 'hosts' -name $vm_host.Sku.Name)
                }
            }
            catch {                
                $sub.Id
                $vm_host.ResourceGroupName.ToLower()
                $host_group.Name
                $vm_host.Name
                $params
            }            
        }
    }
    [system.gc]::Collect()

    # Add subtotals to the usage array
    
    #$subtotal.psobject.properties.name | Foreach-Object {$total.$_ += $subtotal.$_}
     
    $Date = Get-Date -Format "yyy-MM-dd"
    
    $Time = Get-Date -Format "HH:mm:ss"
    if ($ShowEC){
        $ahb_ec = ($subtotal.ahb_std + $subtotal.ahb_ent*4)
        $payg_ec = ($subtotal.payg_std + $subtotal.payg_ent*4)
    }else{
        $ahb_ec = 0
        $payg_ec = 0
    }
    if ($useDatabase){
        $propertiesToSplat.Query = $insertSQL -f $Date, $Time, $sub.Name, $sub.Id, $ahb_ec, $payg_ec, $subtotal.ahb_std, $subtotal.ahb_ent, $subtotal.payg_std, $subtotal.payg_ent, $subtotal.hadr_std, $subtotal.hadr_ent, $subtotal.developer, $subtotal.express, $subtotal.unreg_sqlvm, $subtotal.unknown_tier
        Invoke-SQLCmd @propertiesToSplat
    }else{
        $usageTable += ,(@( $Date, $Time, $sub.Name, $sub.Id, $ahb_ec, $payg_ec, $subtotal.ahb_std, $subtotal.ahb_ent, $subtotal.payg_std, $subtotal.payg_ent, $subtotal.hadr_std, $subtotal.hadr_ent, $subtotal.developer, $subtotal.express, $subtotal.unreg_sqlvm, $subtotal.unknown_tier))
    }
}

if ($useDatabase){
    Write-Host ([Environment]::NewLine + "-- Added the usage data to $tableName table --")  
}else{
    
    # Write usage data to the .csv file

     (ConvertFrom-Csv ($usageTable | %{$_ -join ','})) | Export-Csv $FilePath -Append -NoType
    Write-Host ([Environment]::NewLine + "-- Added the usage data to $FilePath --")
}

