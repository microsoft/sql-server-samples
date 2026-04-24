param (
    [Parameter (Mandatory=$true)]
    [string]$AzureSubscriptionId,
    [Parameter (Mandatory=$true)]
    [string]$AzureResourceGroup,
    [Parameter (Mandatory=$true)]
    [string]$AzureRegion,
    [Parameter (Mandatory=$false)]
    [string]$SqlServerInstanceName,
    [Parameter (Mandatory=$false)]
    [string]$SqlServerAdminAccounts = "BUILTIN\ADMINISTRATORS",
    [Parameter (Mandatory=$false)]
    [string]$SqlServerSvcAccount = "NT AUTHORITY\NETWORK SERVICE",
    [Parameter (Mandatory=$false)]
    [string]$SqlServerSvcPassword,
    [Parameter (Mandatory=$false)]
    [string]$AgtServerSvcAccount = "NT AUTHORITY\NETWORK SERVICE",
    [Parameter (Mandatory=$false)]
    [string]$AgtServerSvcPassword,
    [Parameter (Mandatory=$true)]
    [string]$IsoFolder,
    [Parameter (Mandatory=$false)]
    [string]$Proxy
)

# This function checks if the specified module is imported into the session and if not installes and/or imports it
function LoadModule
{
    param (
        [parameter(Mandatory = $true)][string] $name
    )

    $retVal = $true

    if (!(Get-Module -Name $name))
    {
        $retVal = Get-Module -ListAvailable | Where-Object {$_.Name -eq $name}

        if ($retVal)
        {
            try
            {
                Import-Module $name -ErrorAction SilentlyContinue
            }
            catch
            {
                write-host "The request to lload module $($name) failed with the following error:"
                write-host $_.Exception.Message                
                $retVal = $false
            }
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $name) {
                Install-Module -Name $name -Force -Scope CurrentUser
                try
                {
                Import-Module $name -ErrorAction SilentlyContinue
                }
                catch
                {
                    write-host "The request to lload module $($name) failed with the following error:"
                    write-host $_.Exception.Message                
                    $retVal = $false
                }
            }
            else {

                # If module is not imported, not available and not in online gallery then abort
                write-host "Module $($name) not imported, not available and not in online gallery, exiting."
                EXIT 1
            }
        }
    }

    return $retVal
}

try {
    
    write-host "==== Ensure PS version and load missing Azure modules ===="
    #
    # Suppress warnings
    #
    Update-AzConfig -DisplayBreakingChangeWarning $false

    # Load required modules
    $requiredModules = @(
        "AzureAD",    
        "Az.Accounts",
        "Az.Resources",
        "Az.ConnectedMachine",
        "Az.ResourceGraph"
    )
    $requiredModules | Foreach-Object {LoadModule $_}

    write-host "==== Check if setup.exe is already running and kill it if so ===="
  
    if (Get-Process setup -ErrorAction SilentlyContinue) {
        Stop-Process -Name setup -Force
        Write-Host "Existing setup.exe process terminated."
    }

    write-host "==== Log in to Azure ===="

    Update-AzConfig -EnableLoginByWam $false
    Connect-AzAccount | Out-Null
    $subscription = Get-AzSubscription -SubscriptionId $AzureSubscriptionId -ErrorAction SilentlyContinue
    if (-not $subscription) {
        Write-Error "Azure subscription with ID '$AzureSubscriptionId' does not exist."
        exit
    }
    Set-AzContext -Subscription $AzureSubscriptionId | Out-Null
    
    write-host "==== Block auto-onboarding to Arc ===="

    $existingResourceGroup = Get-AzResourceGroup -Name $AzureResourceGroup -ErrorAction SilentlyContinue

    if ($existingResourceGroup) {
        $tags = @{"ArcOnboarding" = "Blocked"}
        Set-AzResourceGroup -Name $AzureResourceGroup -Tag $tags | Out-Null
    } else {
        Write-Error "Resource group '$AzureResourceGroup' does not exist."
        exit
    }    

    write-host "==== Mount the ISO file as a volume ===="

     # Retrieve the product key if any
 
    $keyFiles = (Get-ChildItem $IsoFolder -Filter "*.txt")
    $productKey = ""
    foreach ($keyFile in $keyFiles) {
        # Read each line from the file
        Get-Content $keyFile.fullname | ForEach-Object {
            if ($_ -match "[A-Z0-9]{5,}-[A-Z0-9]{5,}-[A-Z0-9]{5,}-[A-Z0-9]{5,}-[A-Z0-9]{4,}.*") {
                # Extract the product key (including any following string after a space)
                $productKey = [regex]::Match($_, '[A-Z0-9]{5,}-[A-Z0-9]{5,}-[A-Z0-9]{5,}-[A-Z0-9]{5,}-[A-Z0-9]{4,}.*').Value
                # Strip any text after the product key
                $productKey = $productKey -replace " .*$"
            }
        }    
    }
        

    $isoFiles = (Get-ChildItem $IsoFolder -Filter "*.iso")
    
    
   # Pick the .iso file and mount

    $noKeylist = "SQLFULL_ENU_ENTVL.iso", "SQLFULL_ENU_STDVL.iso", "SQLServer2022-x64-ENU-Ent.iso", "SQLServer2022-x64-ENU-Std.iso"

    foreach ($isoFile in $isoFiles) {
        write-host("****isoFile: $($isoFile)")
        $imagePath = $isoFile.FullName
        if ($noKeylist -contains $isoFile.Name) {$productKey = ""}
        if (!(Get-DiskImage -ImagePath $imagePath).Attached) {
            $mountResult = Mount-DiskImage -ImagePath $imagePath -PassThru
        } else {
            $mountResult = Get-DiskImage -ImagePath $imagePath 
        }
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        Write-Host "ISO file $($isoFile.Name) mounted as drive $($driveLetter):"
        break
    }

    
    write-host "==== Run unattended SQL Server setup from the mounted volume ===="

   
    # Launch setup

    $setupPath = ($driveLetter + ":\setup.exe")
   

    $argumentList = "/q  /ACTION=Install  /FEATURES=SQL  /SQLSVCACCOUNT=`"$($SqlServerSvcAccount)`"  /SQLSYSADMINACCOUNTS=`"$($SqlServerAdminAccounts)`"  /AGTSVCACCOUNT=`"$($AgtServerSvcAccount)`" /IACCEPTSQLSERVERLICENSETERMS"
        # some optional arguments
    if ($SqlServerInstanceName) {
       $argumentList += " /INSTANCENAME= $($SqlServerInstanceName)"
    } 
    if ($productKey) {
        $argumentList += " /PID=`"$($productKey)`""
    } 
    
    if ($SqlServerSvcPassword) {
        $argumentList += " /SQLSVCPASSWORD=`"$($SqlServerSvcPassword)`""
    }
    
    if ($AgtSvCPassword) {
        $argumentList += " /AGTSVCPASSWORD=`"$($AgtSvCPassword)`""
    }
   
    
    Start-Process -Wait -FilePath $setupPath -ArgumentList $argumentList -RedirectStandardOutput setup-output.txt


    Dismount-DiskImage -ImagePath $imagePath | Out-Null

    write-host "==== Onboard the VM to Azure Arc ===="

    $hostName = (Get-WmiObject Win32_ComputerSystem).Name

    if ($Proxy) {
	    Connect-AzConnectedMachine -ResourceGroupName $AzureResourceGroup -Name $hostName -Location $AzureRegion -Proxi $Proxy | Out-Null
    } else {
	    Connect-AzConnectedMachine -ResourceGroupName $AzureResourceGroup -Name $hostName -Location $AzureRegion | Out-Null
    }
    
    write-host "==== Install SQL Arc extension with LT=PAYG and upgrade to the latest version ===="


    $Settings = @{
        SqlManagement = @{ IsEnabled = $true };        
        LicenseType = "PAYG";
        enableExtendedSecurityUpdates = $False;
    }

  
    New-AzConnectedMachineExtension -ResourceGroupName $AzureResourceGroup -MachineName $hostName -Name "WindowsAgent.SqlServer" -Publisher "Microsoft.AzureData" -ExtensionType "WindowsAgent.SqlServer" -Location $AzureRegion -Settings $Settings -EnableAutomaticUpgrade

    
    write-host "==== Display the status of the billable Arc-enabled host ===="

    $query = "
    resources
    | where type =~ 'Microsoft.HybridCompute/machines'
    | where subscriptionId =~ '$($AzureSubscriptionId)'
    | where resourceGroup =~ '$($AzureResourceGroup)'
    | extend status = tostring(properties.status)
    | where status =~ 'Connected'
    | extend machineID = tolower(id)
    | extend VMbyManufacturer = toboolean(iff(properties.detectedProperties.manufacturer in (
            'VMware',
            'QEMU',
            'Amazon EC2',
            'OpenStack',
            'Hetzner',
            'Mission Critical Cloud',
            'DigitalOcean',
            'UpCloud',
            'oVirt',
            'Alibaba',
            'KubeVirt',
            'Parallels',
            'XEN'
        ), 1, 0))
    | extend VMbyModel = toboolean(iff(properties.detectedProperties.model in (
            'OpenStack',
            'Droplet',
            'oVirt',
            'Hypervisor',
            'Virtual',
            'BHYVE',
            'KVM'
        ), 1, 0))
    | extend GoogleVM = toboolean(iff((properties.detectedProperties.manufacturer =~ 'Google') and (properties.detectedProperties.model =~ 'Google Compute Engine'), 1, 0))
    | extend NutanixVM = toboolean(iff((properties.detectedProperties.manufacturer =~ 'Nutanix') and (properties.detectedProperties.model =~ 'AHV'), 1, 0))
    | extend MicrosoftVM = toboolean(iff((properties.detectedProperties.manufacturer =~ 'Microsoft Corporation') and (properties.detectedProperties.model =~ 'Virtual Machine'), 1, 0))
    | extend billableCores = iff(VMbyManufacturer or VMbyModel or GoogleVM or NutanixVM or MicrosoftVM, properties.detectedProperties.logicalCoreCount, properties.detectedProperties.coreCount)        
    | join kind = leftouter // Join Extension
            (
            resources
            | where type =~ 'Microsoft.HybridCompute/machines/extensions'
            | where name == 'WindowsAgent.SqlServer' or name == 'LinuxAgent.SqlServer'
            | extend extMachineID = substring(id, 0, indexof(id, '/extensions'))
            | extend extensionId = id
            )
            on `$left.id == `$right.extMachineID
            | join kind = inner       // Join SQL Arc
                (
                resources
                | where type =~ 'microsoft.azurearcdata/sqlserverinstances'
                | extend sqlVersion = tostring(properties.version)
                | extend sqlEdition = tostring(properties.edition) 
                | extend is_Enterprise = toint(iff(sqlEdition == 'Enterprise', 1, 0))
                | extend sqlStatus = tostring(properties.status)
                | extend licenseType = tostring(properties.licenseType)
                | where sqlEdition in ('Enterprise', 'Standard') 
                | where licenseType !~ 'HADR'
                | where sqlStatus =~ 'Connected'
                | extend ArcServer = tolower(tostring(properties.containerResourceId))
                | order by sqlEdition
                )
                on `$left.machineID == `$right.ArcServer
                | where isnotnull(extensionId)
                | summarize Edition = iff(sum(is_Enterprise) > 0, 'Enterprise', 'Standard') by machineID
                , name
                , resourceGroup
                , subscriptionId
                , Model = tostring(properties.detectedProperties.model)
                , Manufacturer = tostring(properties.detectedProperties.manufacturer)
                , License_Type = tostring(properties1.settings.LicenseType)
                , OS = tostring(properties.osName)
                , Uses_UV = tostring(properties1.settings.UsePhysicalCoreLicense.IsApplied)
                , Cores = tostring(billableCores)
                , Version = sqlVersion
                | project-away machineID
                | order by Edition, name asc
    "
    Search-AzGraph -Query $query

} catch {
    Write-Error "An error occurred: $_"
    # You can add additional error handling logic here
} finally {
    # Cleanup or other actions that should always run
    Write-Host "==== Installation completed ===="
}
