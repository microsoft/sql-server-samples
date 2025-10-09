$parameters = $args[0]

$subscriptionId = $parameters['subscriptionId']
$resourceGroupName = $parameters['resourceGroupName']
$virtualNetworkName = $parameters['virtualNetworkName']
$subnetName = $parameters['subnetName']
$force =  $parameters['force']

$NSnetworkModels = "Microsoft.Azure.Commands.Network.Models"
$NScollections = "System.Collections.Generic"

function VerifyPSVersion {
    Write-Host "Verifying PowerShell version."
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        if (($PSVersionTable.PSVersion.Major -ge 6) -or
        (($PSVersionTable.PSVersion.Major -eq 5) -and ($PSVersionTable.PSVersion.Minor -ge 1))) {
            Write-Host "PowerShell version verified." -ForegroundColor Green
        }
        else {
            Write-Host "You need to install PowerShell version 5.1 or higher." -ForegroundColor Red
            Break;
        }
    }
    else {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Host "PowerShell version verified." -ForegroundColor Green
        }
        else {
            Write-Host "You need to install PowerShell version 6.0 or higher." -ForegroundColor Red
            Break;
        }
    }
}

function EnsureAzModule {
    Write-Host "Checking if Az module is imported."
    $module = Get-Module Az
    If ($null -eq $module) {
        try {
            Import-Module Az -ErrorAction Stop
            Write-Host "Module Az imported." -ForegroundColor Green
        }
        catch {
            Install-Module Az -AllowClobber
            Write-Host "Module Az installed." -ForegroundColor Green
        }
    } else {
        Write-Host "Module Az imported." -ForegroundColor Green
    }
}

function EnsureLogin () {
    $context = Get-AzContext
    If ($null -eq $context.Subscription) {
        Write-Host "Signing in..."
        If ($null -eq (Connect-AzAccount -ErrorAction SilentlyContinue -ErrorVariable Errors)) {
            Write-Host ("Sign-in failed: {0}" -f $Errors[0].Exception.Message) -ForegroundColor Red
            Break
        }
    }
    Write-Host "Signed in successfully." -ForegroundColor Green
}

function SelectSubscriptionId {
    param (
        $subscriptionId
    )
    Write-Host "Selecting subscription '$subscriptionId'."
    $context = Get-AzContext
    If($context.Subscription.Id -ne $subscriptionId)
    {
        Try
        {
            Select-AzSubscription -SubscriptionId $subscriptionId -ErrorAction Stop | Out-null
        }
        Catch
        {
            Write-Host "Subscription selection failed: $_" -ForegroundColor Red
            Break
        }
    }
    Write-Host "Subscription selected." -ForegroundColor Green
}

function LoadVirtualNetwork {
    param (
        $resourceGroupName,
        $virtualNetworkName
    )
        Write-Host("Loading virtual network '{0}' in resource group '{1}'." -f $virtualNetworkName, $resourceGroupName)
        $virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        If($null -ne $virtualNetwork.Id)
        {
            Write-Host "Virtual network loaded." -ForegroundColor Green
            return $virtualNetwork
        }
        else
        {
            Write-Host "Virtual network not found." -ForegroundColor Red
            Break
        }
}

function LoadVirtualNetworkSubnet {
    param (
        $virtualNetwork,
        $subnetName
    )
        Write-Host("Loading subnet '{0}'." -f $subnetName)
        $subnets = $virtualNetwork.Subnets.Name
        If($true -eq $subnets.Contains($subnetName))
        {
            $subnetIndex = $subnets.IndexOf($subnetName)
            $subnet = $virtualNetwork.Subnets[$subnetIndex]
            Write-Host "Subnet loaded." -ForegroundColor Green
            return $subnet
        }
        else
        {
            Write-Host "Subnet not found." -ForegroundColor Red
            Break
        }
}

function VerifySubnet {
    param (
        $subnet
    )
        Write-Host("Verifying subnet '{0}'." -f $subnet.Name)
        If($subnet.AddressPrefix.Split('/')[1] -le 28)
        {
            Write-Host "Passed Validation - Subnet is of enough size." -ForegroundColor Green
        }
        Else
        {
            Write-Host "Failed Validation - Minimum supported subnet size is /28." -ForegroundColor Red
            Break
        }
        If(
            ($subnet.IpConfigurations.Count -eq 0) -and
            (
                ($subnet.ResourceNavigationLinks.Count -eq 0) -or
                ($subnet.ResourceNavigationLinks[0].LinkedResourceType -eq 'Microsoft.Sql/virtualClusters')
            )
          )
        {
            Write-Host "Passed Validation - There are no conflicting resources inside the subnet." -ForegroundColor Green
        }
        Else
        {
            Write-Host "Failed Validation - Subnet is already in use." -ForegroundColor Red
            Break
        }
}

function VerifyDelegation {
    param (
        $subnet
    )

    $result = @{
        isDelegatedToManagedInstance = $false;
        isDelegated = $false;
        success = $false;
    }

    $delegation = Get-AzDelegation -Subnet $subnet

    If($delegation -ne $null)
    {
        $result['isDelegated'] = $true
        $result['isDelegatedToManagedInstance'] = $delegation.ServiceName -eq "Microsoft.Sql/managedInstances"
    }

    $result['success'] = -not $result['isDelegated'] -or $result['isDelegatedToManagedInstance']

    return $result
}

function LoadNetworkSecurityGroup {
    param (
        $subnet
    )
    Write-Host("Loading Network security group for subnet '{0}'." -f $subnet.Name)
    If(
        $null -ne $subnet.NetworkSecurityGroup
      )
    {
        $nsgSegments = ($subnet.NetworkSecurityGroup.Id).Split("/", [System.StringSplitOptions]::RemoveEmptyEntries)
        $nsgName = $nsgSegments[-1].Trim()
        $nsgResourceGroup = $nsgSegments[3].Trim()
        $networkSecurityGroup = Get-AzNetworkSecurityGroup -ResourceGroupName $nsgResourceGroup -Name $nsgName
        Write-Host "Network security group security group loaded." -ForegroundColor Green
        return $networkSecurityGroup
    }
    Else
    {
        return $null
    }
}

function HasNSG {
    param (
        $subnet
    )

    $nsg = LoadNetworkSecurityGroup $subnet
    return $nsg -ne $null
}

function LoadRouteTable {
    param (
        $subnet
    )
        Write-Host("Loading Route table for subnet '{0}'." -f $subnet.Name)
        If(
            $null -ne $subnet.RouteTable
          )
        {
            $rtSegments = ($subnet.RouteTable.Id).Split("/", [System.StringSplitOptions]::RemoveEmptyEntries)
            $rtName = $rtSegments[-1].Trim()
            $rtResourceGroup = $rtSegments[3].Trim()
            $routeTable = Get-AzRouteTable -ResourceGroupName $rtResourceGroup -Name $rtName
            Write-Host "Route table loaded." -ForegroundColor Green
            return $routeTable
        }
        return $null
}

function HasRouteTable {
    param (
        $subnet
    )

    $routeTable = LoadRouteTable $subnet
    return $routeTable -ne $null
}

function CreateNSG
{
    param(
        $virtualNetwork,
        $subnet
    )

    Write-Host "Creating Network security group."
    $networkSecurityGroupName = "nsgManagedInstance" + (Get-Random -Maximum 1000)

    $securityRules = New-Object "$NScollections.List``1[$NSnetworkModels.PSSecurityRule]"

    $rule = New-AzNetworkSecurityRuleConfig `
        -Name prepare-allow_tds_inbound `
        -Description "Allow access to data" `
        -Direction Inbound -Priority 1000 -Access Allow -Protocol Tcp `
        -SourceAddressPrefix VirtualNetwork -DestinationAddressPrefix $subnet.AddressPrefix `
        -SourcePortRange * -DestinationPortRange "1433"
    $securityRules.Add($rule)


    $rule = New-AzNetworkSecurityRuleConfig `
        -Name prepare-deny_all_inbound `
        -Description "Deny all other inbound traffic" `
        -Direction Inbound -Priority 4096 -Access Deny -Protocol * `
        -SourceAddressPrefix * -DestinationAddressPrefix * `
        -SourcePortRange * -DestinationPortRange *
    $securityRules.Add($rule)

    $rule = New-AzNetworkSecurityRuleConfig `
        -Name prepare-deny_all_outbound `
        -Description "Deny all other outbound traffic" `
        -Direction Outbound -Priority 4096 -Access Deny -Protocol * `
        -SourceAddressPrefix * -DestinationAddressPrefix * `
        -SourcePortRange * -DestinationPortRange *
    $securityRules.Add($rule)

    Try
    {
        $networkSecurityGroup = New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $virtualNetwork.ResourceGroupName -Location $virtualNetwork.Location -SecurityRules $securityRules
    }
    Catch
    {
        Write-Host "Failed: $_" -ForegroundColor Red
    }

    Write-Host "Associating Network security group."
    $subnet.NetworkSecurityGroup = $networkSecurityGroup
}

function CreateRouteTable
{
    param(
        $virtualNetwork,
        $subnet
    )
    Write-Host "Creating Route table."
    $routeTableName = "rtManagedInstance" + (Get-Random -Maximum 1000)

    Try
    {
        $routeTable = New-AzRouteTable -Name $routeTableName -ResourceGroupName $virtualNetwork.ResourceGroupName -Location $virtualNetwork.Location
    }
    Catch
    {
        Write-Host "Failed: $_" -ForegroundColor Red
    }

    Write-Host "Associating Route table."
    $subnet.RouteTable = $routeTable
}

function DelegateSubnet
{
    param(
        $subnet
    )

    Write-Host "Creating Subnet Delegation for Managed Instance."


    $subnet.Delegations = New-Object "$NScollections.List``1[$NSnetworkModels.PSDelegation]"
    $delegationName = "dgManagedInstance" + (Get-Random -Maximum 1000)

    Try
    {
        $delegation = New-AzDelegation -Name $delegationName -ServiceName "Microsoft.Sql/managedInstances"
    }
    Catch
    {
        Write-Host "Failed: $_" -ForegroundColor Red
    }

    Write-Host "Associating Subnet Delegation for Managed Instance."
    $subnet.Delegations.Add($delegation)
}

function SetVirtualNetwork
{
    param($virtualNetwork)

    Write-Host "Applying changes to the virtual network."
    Try
    {
        Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    }
    Catch
    {
        Write-Host "Failed: $_" -ForegroundColor Red
    }

}

VerifyPSVersion
EnsureAzModule
EnsureLogin
SelectSubscriptionId -subscriptionId $subscriptionId

$virtualNetwork = LoadVirtualNetwork -resourceGroupName $resourceGroupName -virtualNetworkName $virtualNetworkName
$subnet = LoadVirtualNetworkSubnet -virtualNetwork $virtualNetwork -subnetName $subnetName

Write-Host

$delegationVerificationResult = VerifyDelegation $subnet

If($delegationVerificationResult['success'])
{
    VerifySubnet $subnet
    $hasNsg = HasNSG $subnet
    $hasRouteTable = HasRouteTable $subnet
    $isValid = $delegationVerificationResult['isDelegatedToManagedInstance'] -and $hasNsg -and $hasRouteTable

    If($isValid -ne $true)
    {
        Write-Host
        Write-Host("----------  To delegate the virtual network subnet for Managed Instance this script will: --------------- ")  -ForegroundColor Yellow
        Write-Host

        If(-not $hasNsg)
        {
            Write-Host "Create Network security group and associate it to the subnet." -ForegroundColor Yellow
        }

        If(-not $hasRouteTable)
        {
            Write-Host "Create Route table and associate it to the subnet." -ForegroundColor Yellow
        }

        If(-not $delegationVerificationResult['isDelegatedToManagedInstance'])
        {
            Write-Host "Delegate subnet to Managed Instance." -ForegroundColor Yellow
        }

        Write-Host
        Write-Host("-------------------------------------------------------------------------------------------------------- ")  -ForegroundColor Yellow
        Write-Host


        $applyChanges = $force

        If($applyChanges -ne $true)
        {
            $reply = Read-Host -Prompt "Do you want to make these changes? [y/n]"
            $applyChanges = $reply -match "[yY]"
            Write-Host
        }

        If ($applyChanges)
        {
            If(-not $hasNsg)
            {
                CreateNSG $virtualNetwork $subnet
            }

            If(-not $hasRouteTable)
            {
                CreateRouteTable $virtualNetwork $subnet
            }

            If(-not $delegationVerificationResult['isDelegatedToManagedInstance'])
            {
                DelegateSubnet $subnet
            }

            SetVirtualNetwork $virtualNetwork

            Write-Host
            Write-Host "Subnet delegated to the Managed Instance." -ForegroundColor Green
            Write-Host "https://portal.azure.com/#create/Microsoft.SQLManagedInstance"
        }
        Else
        {
            Write-Host
            Write-Host "Subnet delegation canceled." -ForegroundColor Yellow
        }
    }
    Else
    {
            Write-Host "Subnet is already delegated to the Managed Instance." -ForegroundColor Green
            Write-Host "https://portal.azure.com/#create/Microsoft.SQLManagedInstance"
    }
}
Else
{
    Write-Host
    Write-Host "Subnet is already delegated to other service." -ForegroundColor Red
}
