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
            Write-Host "You need to install PowerShell version 5.1 or heigher." -ForegroundColor Red
            Break;
        }
    }
    else {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Host "PowerShell version verified." -ForegroundColor Green
        }
        else {
            Write-Host "You need to install PowerShell version 6.0 or heigher." -ForegroundColor Red
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
        Write-Host "Sign-in..."
        If ($null -eq (Connect-AzAccount -ErrorAction SilentlyContinue -ErrorVariable Errors)) {
            Write-Host ("Sign-in failed: {0}" -f $Errors[0].Exception.Message) -ForegroundColor Red
            Break
        }
    }
    Write-Host "Sign-in successful." -ForegroundColor Green
}


function ConvertCidrToUint32Array
{
    param(
        $cidrRange
    )
    $cidrRangeParts = $cidrRange.Split([char]".",[char]"/")

    If(
        ($cidrRangeParts[0] -eq 0) -and `
        ($cidrRangeParts[1] -eq 0) -and `
        ($cidrRangeParts[2] -eq 0) -and `
        ($cidrRangeParts[3] -eq 0) -and `
        ($cidrRangeParts[4] -eq 0)
        )
    {
        return @(0, [System.Int32]::MaxValue)
    }
    
    $ipnum = ([Convert]::ToUInt32($cidrRangeParts[0]) -shl 24) -bor `
             ([Convert]::ToUInt32($cidrRangeParts[1]) -shl 16) -bor `
             ([Convert]::ToUInt32($cidrRangeParts[2]) -shl 8) -bor `
             [Convert]::ToUInt32($cidrRangeParts[3])

    $maskbits = [System.Convert]::ToInt32($cidrRangeParts[4])
    $mask = 0xffffffff
    $mask = $mask -shl (32 -$maskbits)
    $ipstart = $ipnum -band $mask
    $ipend = $ipnum -bor ($mask -bxor 0xffffffff)
    return @($ipstart, $ipend)
}

function ContainsCidr
{
    param(
        $cidrRangeA, 
        $cidrRangeB
    )
    $a = ConvertCidrToUint32Array $cidrRangeA
    $b = ConvertCidrToUint32Array $cidrRangeB

    return `
        (($a[0] -le $b[0]) -and ($a[1] -ge $b[1]))
}

function HasCidrOverlap
{
    param($cidrRangeA, $cidrRangeB)
    $a = ConvertCidrToUint32Array $cidrRangeA
    $b = ConvertCidrToUint32Array $cidrRangeB

    return `
        (($a[0] -ge $b[0]) -and ($a[0] -lt $b[1])) -or `
        (($a[1] -le $b[1]) -and ($a[1] -gt $b[0])) -or `
        (($a[0] -le $b[0]) -and ($a[1] -ge $b[1]))
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


function VerifyServiceEndpoints {
    param (
        $subnet
    )
        Write-Host("Verifying Service endpoints for subnet '{0}'." -f $subnet.Name)
        If(
            $subnet.ServiceEndpoints.Count -eq 0
          )
        {
            Write-Host "Passed Validation - No service endpoints." -ForegroundColor Green
            return $true
        }
        Else
        {
            Write-Host "Warning - Service endpoints are not supported." -ForegroundColor Yellow
            return $false
        }
}
function VerifyServiceDelegation {
    param (
        $subnet
    )
        Write-Host("Verifying Service Delegation for subnet '{0}'." -f $subnet.Name)
        If(
            (Get-AzDelegation -Subnet $subnet).ServiceName -eq 'Microsoft.Sql/managedInstances'
          )
        {
            Write-Host "Passed Validation - `'Microsoft.Sql/managedInstances`' delegated to subnet $($subnet.Name)." -ForegroundColor Green
            return $true
        }
        Else
        {
            Write-Host "Warning - `'Microsoft.Sql/managedInstances`' is not delegated to subnet $($subnet.Name)." -ForegroundColor Yellow
            return $false
        }
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

function DefineSecurityRules{

        $securityRules = New-Object "$NScollections.List``1[$NSnetworkModels.PSSecurityRule]"
        #begin NSG inbound rules
        $rule = New-AzNetworkSecurityRuleConfig `
            -Name prepare-allow-management-inbound `
            -Description "Allow inbound TCP traffic on ports 9000,9003,1438,1440,1452" `
            -Direction Inbound -Priority 110 -Access Allow -Protocol Tcp `
            -SourceAddressPrefix * -DestinationAddressPrefix * `
            -SourcePortRange * -DestinationPortRange @(9000, 9003, 1438, 1440, 1452)
        $securityRules.Add($rule)
        $rule = New-AzNetworkSecurityRuleConfig `
            -Name prepare-allow-mi_subnet-inbound `
            -Description "Allow inbound inter-node traffic" `
            -Direction Inbound -Priority 160 -Access Allow -Protocol * `
            -SourceAddressPrefix $subnet.AddressPrefix -DestinationAddressPrefix * `
            -SourcePortRange * -DestinationPortRange *
        $securityRules.Add($rule)
        $rule = New-AzNetworkSecurityRuleConfig `
            -Name prepare-allow-health_probe-inbound `
            -Description "Allow health probe inbound" `
            -Direction Inbound -Priority 170 -Access Allow -Protocol * `
            -SourceAddressPrefix AzureLoadBalancer -DestinationAddressPrefix * `
            -SourcePortRange * -DestinationPortRange *
        $securityRules.Add($rule)
        #end NSG inbound rules
        #begin NSG outbound rules
        $rule = New-AzNetworkSecurityRuleConfig `
            -Name prepare-allow-management-outbound `
            -Description "Allow outbound TCP traffic on port 80,443,12000" `
            -Direction Outbound -Priority 110 -Access Allow -Protocol Tcp `
            -SourceAddressPrefix * -DestinationAddressPrefix AzureCloud `
            -SourcePortRange * -DestinationPortRange @(80, 443, 12000)
        $securityRules.Add($rule)
        $rule = New-AzNetworkSecurityRuleConfig `
            -Name prepare-allow-mi_subnet-outbound `
            -Description "Allow outbound inter-node traffic" `
            -Direction Outbound -Priority 140 -Access Allow -Protocol * `
            -SourceAddressPrefix * -DestinationAddressPrefix $subnet.AddressPrefix `
            -SourcePortRange * -DestinationPortRange *
        $securityRules.Add($rule)
        #end NSG outbound rules

        return $securityRules
}

function VerifyAddressPrefix {
    param (
        $nsgRuleAddressPrefixes,
        $securityRuleAddressPrefix
    )
    
    ForEach($nsgRuleAddressPrefix in $nsgRuleAddressPrefixes) {
        If($nsgRuleAddressPrefix -eq "*"){
            return $true;
        }

        If($nsgRuleAddressPrefix -eq $securityRuleAddressPrefix){
            return $true;
        }

        If(($true -ne $securityRuleAddressPrefix.Contains('/')) -or ($true -ne $nsgRuleAddressPrefix.Contains('/'))) {
            continue;
        }

        return ContainsCidr -cidrRangeA $nsgRuleAddressPrefix -cidrRangeB $securityRuleAddressPrefix
    }

    return $false
}

function VerifyDenyRuleAddressPrefix {
    param (
        $nsgRuleAddressPrefixes,
        $securityRuleAddressPrefix
    )
    
    ForEach($nsgRuleAddressPrefix in $nsgRuleAddressPrefixes) {
        If($nsgRuleAddressPrefix -eq "*"){
            return $true;
        }

        If($nsgRuleAddressPrefix -eq $securityRuleAddressPrefix){
            return $true;
        }

        If(($true -ne $securityRuleAddressPrefix.Contains('/')) -or ($true -ne $nsgRuleAddressPrefix.Contains('/'))) {
            continue;
        }

        return HasCidrOverlap -cidrRangeA $nsgRuleAddressPrefix -cidrRangeB $securityRuleAddressPrefix
    }

    return $false
}

function IsPrivateCidr
{    
    param($cidrRange)
    return `
        (ContainsCidr "10.0.0.0/8" $cidrRange) -or `
        (ContainsCidr "172.16.0.0/12" $cidrRange) -or `
        (ContainsCidr "192.168.0.0/16" $cidrRange)
}


function ContainsPort{
    param(
        $nsgRulePort,
        $securityRulePort
    )

    If($nsgRulePort.Contains('-')){
        $startPort = [Int32]::Parse($nsgRulePort.Split('-')[0])
        $endPort =  [Int32]::Parse($nsgRulePort.Split('-')[1])
        $port = [Int32]::Parse($securityRulePort)
        return $startPort -le $port -and $port -le $endPort
    }
    else{
        return $nsgRulePort -eq $securityRulePort
    }
}

function VerifyPort {
    param (
        $nsgRulePorts,
        $securityRulePort
    )
    
    ForEach($nsgRulePort in $nsgRulePorts) {
        If($true -eq (ContainsPort -nsgRulePort $nsgRulePort -securityRulePort $securityRulePort)) {
            return $true
        }
    }

    return $false
}

function VerifyNSGRule {
    param (
        $securityRule,
        $nsgRule
    )

    If($securityRule.Direction -ne $nsgRule.Direction) {
        return $false
    }

    If($nsgRule.Access -eq "Allow") {
        If(($nsgRule.Protocol -ne "*") -and ($nsgRule.Protocol -ne $securityRule.Protocol)) {
            return $false
        }

        If(($true -ne $nsgRule.SourceAddressPrefix.Contains('*')) -and ($true -ne (VerifyAddressPrefix -nsgRuleAddressPrefixes $nsgRule.SourceAddressPrefix -securityRuleAddressPrefix $securityRule.SourceAddressPrefix[0]))) {
            return $false
        }

        If(($true -ne $nsgRule.DestinationAddressPrefix.Contains('*')) -and ($true -ne (VerifyAddressPrefix  -nsgRuleAddressPrefixes $nsgRule.DestinationAddressPrefix -securityRuleAddressPrefix $securityRule.DestinationAddressPrefix[0]))) {
            return $false
        }


        If(($true -ne $nsgRule.SourcePortRange.Contains('*')) -and ($true -ne (VerifyPort -nsgRulePorts $nsgRule.SourcePortRange -securityRulePort $securityRule.SourcePortRange[0]))) {
            return $false
        }

        If(($true -ne $nsgRule.DestinationPortRange.Contains('*')) -and ($true -ne (VerifyPort -nsgRulePorts $nsgRule.DestinationPortRange -securityRulePort $securityRule.DestinationPortRange[0]))) {
            return $false
        }
    }
    Else {
        If(($securityRule.Protocol -ne "*") -and ($nsgRule.Protocol -ne "*") -and ($nsgRule.Protocol -ne $securityRule.Protocol)) {
            return $false
        }

        If(($true -ne $securityRule.SourceAddressPrefix.Contains('*')) -and ($true -ne $nsgRule.SourceAddressPrefix.Contains('*')) -and ($true -ne (VerifyDenyRuleAddressPrefix -nsgRuleAddressPrefixes $nsgRule.SourceAddressPrefix -securityRuleAddressPrefix $securityRule.SourceAddressPrefix[0]))) {
            return $false
        }

        If(($true -ne $securityRule.DestinationAddressPrefix.Contains('*')) -and ($true -ne $nsgRule.DestinationAddressPrefix.Contains('*')) -and ($true -ne (VerifyDenyRuleAddressPrefix  -nsgRuleAddressPrefixes $nsgRule.DestinationAddressPrefix -securityRuleAddressPrefix $securityRule.DestinationAddressPrefix[0]))) {
            return $false
        }


        If(($true -ne $securityRule.SourcePortRange.Contains('*')) -and ($true -ne $nsgRule.SourcePortRange.Contains('*')) -and ($true -ne (VerifyPort -nsgRulePorts $nsgRule.SourcePortRange -securityRulePort $securityRule.SourcePortRange[0]))) {
            return $false
        }

        If(($true -ne $securityRule.DestinationPortRange.Contains('*')) -and ($true -ne $nsgRule.DestinationPortRange.Contains('*')) -and ($true -ne (VerifyPort -nsgRulePorts $nsgRule.DestinationPortRange -securityRulePort $securityRule.DestinationPortRange[0]))) {
            return $false
        }
    }

    return $true

}

function VerifyNSGRules {
    param (
        $securityRule,
        $nsgRules
    )

    ForEach($nsgRule in $nsgRules){
        If(VerifyNSGRule -securityRule $securityRule -nsgRule $nsgRule){
            return ($nsgRule.Access -eq "Allow")
        }        
    }

    return $false
}


function VerifyNSG {
    param (
        $subnet
    )
        $securityRules = DefineSecurityRules

        $result = @{ 
            nsgSecurityRules = New-Object "$NScollections.List``1[$NSnetworkModels.PSSecurityRule]"
            failedSecurityRules = New-Object "$NScollections.List``1[$NSnetworkModels.PSSecurityRule]"
            success = $false 
        }
        Write-Host("Verifying Network security group for subnet '{0}'."-f $subnet.Name)
        $nsg = LoadNetworkSecurityGroup $subnet
        If(
            $null -ne $nsg
          )
        {
            $result['nsgSecurityRules'] = ($nsg.SecurityRules | Sort-Object -Property Priority)

            ForEach($securityRule in $securityRules){
                If($false -eq (VerifyNSGRules -securityRule $securityRule -nsgRules $result['nsgSecurityRules'])){
                    $result['failedSecurityRules'].Add($securityRule)
                }
            }
        }
        $result['success'] = $result['failedSecurityRules'].Count -eq 0
        If($true -eq $result['success'])
        {
            Write-Host "Passed Validation - Network security group." -ForegroundColor Green
        }
        Else
        {
            Write-Host "Warning - Network security group needs modifications." -ForegroundColor Yellow
        }
        return $result
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

function RequiredRoutes{
    param (
        $subnet
    )
    
    $subnet_to_vnetlocal = New-AzRouteConfig -Name "prepare-subnet-to-vnetlocal" -AddressPrefix $subnet.AddressPrefix[0] -NextHopType VnetLocal
    $mi_13_64_11_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-13-64-11-nexthop-internet" -AddressPrefix 13.64.0.0/11	-NextHopType Internet
    $mi_13_96_13_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-13-96-13-nexthop-internet" -AddressPrefix 13.96.0.0/13	-NextHopType Internet
    $mi_13_104_14_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-13-104-14-nexthop-internet" -AddressPrefix 13.104.0.0/14 -NextHopType Internet
    $mi_20_8_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-20-8-nexthop-internet" -AddressPrefix 20.0.0.0/8 -NextHopType Internet
    $mi_23_96_13_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-23-96-13-nexthop-internet" -AddressPrefix 23.96.0.0/13 -NextHopType Internet
    $mi_40_64_10_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-40-64-10-nexthop-internet" -AddressPrefix 40.64.0.0/10 -NextHopType Internet
    $mi_42_159_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-42-159-16-nexthop-internet" -AddressPrefix 42.159.0.0/16 -NextHopType	Internet
    $mi_51_8_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-51-8-nexthop-internet" -AddressPrefix 51.0.0.0/8 -NextHopType Internet
    $mi_52_8_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-52-8-nexthop-internet" -AddressPrefix 52.0.0.0/8 -NextHopType Internet
    $mi_64_4_18_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-64-4-18-nexthop-internet" -AddressPrefix 64.4.0.0/18 -NextHopType Internet
    $mi_65_52_14_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-65-52-14-nexthop-internet" -AddressPrefix 65.52.0.0/14 -NextHopType Internet
    $mi_66_119_144_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-66-119-144-20-nexthop-internet" -AddressPrefix 66.119.144.0/20 -NextHopType Internet
    $mi_70_37_17_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-70-37-17-nexthop-internet" -AddressPrefix 70.37.0.0/17	 -NextHopType Internet
    $mi_70_37_128_18_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-70-37-128-18-nexthop-internet" -AddressPrefix 70.37.128.0/18 -NextHopType Internet
    $mi_91_190_216_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-91-190-216-21-nexthop-internet" -AddressPrefix 91.190.216.0/21 -NextHopType Internet
    $mi_94_245_64_18_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-94-245-64-18-nexthop-internet" -AddressPrefix	94.245.64.0/18 -NextHopType	Internet
    $mi_103_9_8_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-103-9-8-22-nexthop-internet" -AddressPrefix 103.9.8.0/22	-NextHopType Internet
    $mi_103_25_156_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-103-25-156-22-nexthop-internet" -AddressPrefix 103.25.156.0/22 -NextHopType Internet
    $mi_103_36_96_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-103-36-96-22-nexthop-internet" -AddressPrefix 103.36.96.0/22 -NextHopType Internet
    $mi_103_255_140_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-103-255-140-22-nexthop-internet" -AddressPrefix 103.255.140.0/22 -NextHopType Internet
    $mi_104_40_13_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-104-40-13-nexthop-internet" -AddressPrefix 104.40.0.0/13	-NextHopType Internet
    $mi_104_146_15_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-104-146-15-nexthop-internet" -AddressPrefix 104.146.0.0/15 -NextHopType Internet
    $mi_104_208_13_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-104-208-13-nexthop-internet" -AddressPrefix 104.208.0.0/13 -NextHopType Internet
    $mi_111_221_16_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-111-221-16-20-nexthop-internet" -AddressPrefix 111.221.16.0/20 -NextHopType Internet
    $mi_111_221_64_18_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-111-221-64-18-nexthop-internet" -AddressPrefix 111.221.64.0/18 -NextHopType Internet
    $mi_129_75_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-129-75-16-nexthop-internet" -AddressPrefix 129.75.0.0/16 -NextHopType Internet
    $mi_131_253_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-131-253-16-nexthop-internet" -AddressPrefix 131.253.0.0/16 -NextHopType Internet
    $mi_132_245_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-132-245-16-nexthop-internet" -AddressPrefix 132.245.0.0/16 -NextHopType Internet
    $mi_134_170_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-134-170-16-nexthop-internet" -AddressPrefix 134.170.0.0/16 -NextHopType Internet
    $mi_134_177_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-134-177-16-nexthop-internet" -AddressPrefix 134.177.0.0/16 -NextHopType Internet
    $mi_137_116_15_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-137-116-15-nexthop-internet" -AddressPrefix 137.116.0.0/15 -NextHopType Internet
    $mi_137_135_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-137-135-16-nexthop-internet" -AddressPrefix 137.135.0.0/16 -NextHopType Internet
    $mi_138_91_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-138-91-16-nexthop-internet" -AddressPrefix 138.91.0.0/16 -NextHopType Internet
    $mi_138_196_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-138-196-16-nexthop-internet" -AddressPrefix 138.196.0.0/16 -NextHopType Internet
    $mi_139_217_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-139-217-16-nexthop-internet" -AddressPrefix 139.217.0.0/16 -NextHopType Internet
    $mi_139_219_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-139-219-16-nexthop-internet" -AddressPrefix 139.219.0.0/16 -NextHopType Internet
    $mi_141_251_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-141-251-16-nexthop-internet" -AddressPrefix 141.251.0.0/16 -NextHopType Internet
    $mi_146_147_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-146-147-16-nexthop-internet" -AddressPrefix 146.147.0.0/16 -NextHopType Internet
    $mi_147_243_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-147-243-16-nexthop-internet" -AddressPrefix 147.243.0.0/16 -NextHopType Internet
    $mi_150_171_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-150-171-16-nexthop-internet" -AddressPrefix 150.171.0.0/16 -NextHopType Internet
    $mi_150_242_48_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-150-242-48-22-nexthop-internet" -AddressPrefix 150.242.48.0/22 -NextHopType Internet
    $mi_157_54_15_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-157-54-15-nexthop-internet" -AddressPrefix 157.54.0.0/15 -NextHopType Internet
    $mi_157_56_14_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-157-56-14-nexthop-internet" -AddressPrefix 157.56.0.0/14 -NextHopType Internet
    $mi_157_60_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-157-60-16-nexthop-internet" -AddressPrefix 157.60.0.0/16 -NextHopType Internet
    $mi_167_220_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-167-220-16-nexthop-internet" -AddressPrefix 167.220.0.0/16 -NextHopType Internet
    $mi_168_61_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-168-61-16-nexthop-internet" -AddressPrefix 168.61.0.0/16 -NextHopType Internet
    $mi_168_62_15_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-168-62-15-nexthop-internet" -AddressPrefix 168.62.0.0/15 -NextHopType Internet
    $mi_191_232_13_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-191-232-13-nexthop-internet" -AddressPrefix 191.232.0.0/13 -NextHopType Internet
    $mi_192_32_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-32-16-nexthop-internet" -AddressPrefix 192.32.0.0/16 -NextHopType Internet
    $mi_192_48_225_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-48-225-24-nexthop-internet" -AddressPrefix 192.48.225.0/24 -NextHopType Internet
    $mi_192_84_159_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-84-159-24-nexthop-internet" -AddressPrefix 192.84.159.0/24 -NextHopType Internet
    $mi_192_84_160_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-84-160-23-nexthop-internet" -AddressPrefix 192.84.160.0/23 -NextHopType Internet
    $mi_192_100_102_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-100-102-24-nexthop-internet" -AddressPrefix 192.100.102.0/24 -NextHopType Internet
    $mi_192_100_103_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-100-103-24-nexthop-internet" -AddressPrefix 192.100.103.0/24 -NextHopType Internet
    $mi_192_197_157_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-192-197-157-24-nexthop-internet" -AddressPrefix 192.197.157.0/24 -NextHopType Internet
    $mi_193_149_64_19_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-193-149-64-19-nexthop-internet" -AddressPrefix 193.149.64.0/19 -NextHopType Internet
    $mi_193_221_113_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-193-221-113-24-nexthop-internet" -AddressPrefix 193.221.113.0/24 -NextHopType Internet
    $mi_194_69_96_19_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-194-69-96-19-nexthop-internet" -AddressPrefix 194.69.96.0/19 -NextHopType Internet
    $mi_194_110_197_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-194-110-197-24-nexthop-internet" -AddressPrefix 194.110.197.0/24 -NextHopType Internet
    $mi_198_105_232_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-198-105-232-22-nexthop-internet" -AddressPrefix 198.105.232.0/22 -NextHopType Internet
    $mi_198_200_130_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-198-200-130-24-nexthop-internet" -AddressPrefix 198.200.130.0/24	-NextHopType Internet
    $mi_198_206_164_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-198-206-164-24-nexthop-internet" -AddressPrefix 198.206.164.0/24	-NextHopType Internet
    $mi_199_60_28_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-199-60-28-24-nexthop-internet" -AddressPrefix 199.60.28.0/24 -NextHopType Internet
    $mi_199_74_210_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-199-74-210-24-nexthop-internet" -AddressPrefix 199.74.210.0/24 -NextHopType Internet
    $mi_199_103_90_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-199-103-90-23-nexthop-internet" -AddressPrefix 199.103.90.0/23 -NextHopType Internet
    $mi_199_103_122_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-199-103-122-24-nexthop-internet" -AddressPrefix 199.103.122.0/24 -NextHopType Internet
    $mi_199_242_32_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-199-242-32-20-nexthop-internet" -AddressPrefix 199.242.32.0/20 -NextHopType Internet
    $mi_199_242_48_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-199-242-48-21-nexthop-internet" -AddressPrefix 199.242.48.0/21 -NextHopType Internet
    $mi_202_89_224_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-202-89-224-20-nexthop-internet" -AddressPrefix 202.89.224.0/20 -NextHopType Internet
    $mi_204_13_120_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-13-120-21-nexthop-internet" -AddressPrefix 204.13.120.0/21 -NextHopType Internet
    $mi_204_14_180_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-14-180-22-nexthop-internet" -AddressPrefix 204.14.180.0/22 -NextHopType Internet
    $mi_204_79_135_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-135-24-nexthop-internet" -AddressPrefix 204.79.135.0/24 -NextHopType Internet
    $mi_204_79_179_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-179-24-nexthop-internet" -AddressPrefix 204.79.179.0/24 -NextHopType Internet
    $mi_204_79_181_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-181-24-nexthop-internet" -AddressPrefix 204.79.181.0/24 -NextHopType Internet
    $mi_204_79_188_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-188-24-nexthop-internet" -AddressPrefix 204.79.188.0/24 -NextHopType Internet
    $mi_204_79_195_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-195-24-nexthop-internet" -AddressPrefix 204.79.195.0/24 -NextHopType Internet
    $mi_204_79_196_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-196-23-nexthop-internet" -AddressPrefix 204.79.196.0/23 -NextHopType Internet
    $mi_204_79_252_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-79-252-24-nexthop-internet" -AddressPrefix 204.79.252.0/24 -NextHopType Internet
    $mi_204_152_18_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-152-18-23-nexthop-internet" -AddressPrefix 204.152.18.0/23 -NextHopType Internet
    $mi_204_152_140_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-152-140-23-nexthop-internet" -AddressPrefix 204.152.140.0/23 -NextHopType Internet
    $mi_204_231_192_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-192-24-nexthop-internet" -AddressPrefix 204.231.192.0/24 -NextHopType Internet
    $mi_204_231_194_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-194-23-nexthop-internet" -AddressPrefix 204.231.194.0/23 -NextHopType Internet
    $mi_204_231_197_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-197-24-nexthop-internet" -AddressPrefix 204.231.197.0/24 -NextHopType Internet
    $mi_204_231_198_23_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-198-23-nexthop-internet" -AddressPrefix 204.231.198.0/23 -NextHopType Internet
    $mi_204_231_200_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-200-21-nexthop-internet" -AddressPrefix 204.231.200.0/21 -NextHopType Internet
    $mi_204_231_208_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-208-20-nexthop-internet" -AddressPrefix 204.231.208.0/20 -NextHopType Internet
    $mi_204_231_236_24_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-204-231-236-24-nexthop-internet" -AddressPrefix 204.231.236.0/24 -NextHopType Internet
    $mi_205_174_224_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-205-174-224-20-nexthop-internet" -AddressPrefix 205.174.224.0/20 -NextHopType Internet
    $mi_206_138_168_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-206-138-168-21-nexthop-internet" -AddressPrefix 206.138.168.0/21 -NextHopType Internet
    $mi_206_191_224_19_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-206-191-224-19-nexthop-internet" -AddressPrefix 206.191.224.0/19 -NextHopType Internet
    $mi_207_46_16_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-207-46-16-nexthop-internet" -AddressPrefix 207.46.0.0/16	-NextHopType Internet
    $mi_207_68_128_18_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-207-68-128-18-nexthop-internet" -AddressPrefix 207.68.128.0/18 -NextHopType Internet
    $mi_208_68_136_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-208-68-136-21-nexthop-internet" -AddressPrefix 208.68.136.0/21 -NextHopType Internet
    $mi_208_76_44_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-208-76-44-22-nexthop-internet" -AddressPrefix 208.76.44.0/22 -NextHopType Internet
    $mi_208_84_21_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-208-84-21-nexthop-internet" -AddressPrefix 208.84.0.0/21 -NextHopType Internet
    $mi_209_240_192_19_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-209-240-192-19-nexthop-internet" -AddressPrefix 209.240.192.0/19 -NextHopType Internet
    $mi_213_199_128_18_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-213-199-128-18-nexthop-internet" -AddressPrefix 213.199.128.0/18	-NextHopType Internet
    $mi_216_32_180_22_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-216-32-180-22-nexthop-internet" -AddressPrefix 216.32.180.0/22 -NextHopType Internet
    $mi_216_220_208_20_nexthop_internet = New-AzRouteConfig -Name "prepare-mi-216-220-208-20-nexthop-internet" -AddressPrefix 216.220.208.0/20 -NextHopType Internet
    
    $requiredRoutes = New-Object "$NScollections.List``1[$NSnetworkModels.PSRoute]"
    $requiredRoutes.Add($subnet_to_vnetlocal)
    $requiredRoutes.Add($mi_13_64_11_nexthop_internet)
    $requiredRoutes.Add($mi_13_96_13_nexthop_internet)
    $requiredRoutes.Add($mi_13_104_14_nexthop_internet)
    $requiredRoutes.Add($mi_20_8_nexthop_internet)
    $requiredRoutes.Add($mi_23_96_13_nexthop_internet)
    $requiredRoutes.Add($mi_40_64_10_nexthop_internet)
    $requiredRoutes.Add($mi_42_159_16_nexthop_internet)
    $requiredRoutes.Add($mi_51_8_nexthop_internet)
    $requiredRoutes.Add($mi_52_8_nexthop_internet)
    $requiredRoutes.Add($mi_64_4_18_nexthop_internet)
    $requiredRoutes.Add($mi_65_52_14_nexthop_internet)
    $requiredRoutes.Add($mi_66_119_144_20_nexthop_internet)
    $requiredRoutes.Add($mi_70_37_17_nexthop_internet)
    $requiredRoutes.Add($mi_70_37_128_18_nexthop_internet)
    $requiredRoutes.Add($mi_91_190_216_21_nexthop_internet)
    $requiredRoutes.Add($mi_94_245_64_18_nexthop_internet)
    $requiredRoutes.Add($mi_103_9_8_22_nexthop_internet)
    $requiredRoutes.Add($mi_103_25_156_22_nexthop_internet)
    $requiredRoutes.Add($mi_103_36_96_22_nexthop_internet)
    $requiredRoutes.Add($mi_103_255_140_22_nexthop_internet)
    $requiredRoutes.Add($mi_104_40_13_nexthop_internet)
    $requiredRoutes.Add($mi_104_146_15_nexthop_internet)
    $requiredRoutes.Add($mi_104_208_13_nexthop_internet)
    $requiredRoutes.Add($mi_111_221_16_20_nexthop_internet)
    $requiredRoutes.Add($mi_111_221_64_18_nexthop_internet)
    $requiredRoutes.Add($mi_129_75_16_nexthop_internet)
    $requiredRoutes.Add($mi_131_253_16_nexthop_internet)
    $requiredRoutes.Add($mi_132_245_16_nexthop_internet)
    $requiredRoutes.Add($mi_134_170_16_nexthop_internet)
    $requiredRoutes.Add($mi_134_177_16_nexthop_internet)
    $requiredRoutes.Add($mi_137_116_15_nexthop_internet)
    $requiredRoutes.Add($mi_137_135_16_nexthop_internet)
    $requiredRoutes.Add($mi_138_91_16_nexthop_internet)
    $requiredRoutes.Add($mi_138_196_16_nexthop_internet)
    $requiredRoutes.Add($mi_139_217_16_nexthop_internet)
    $requiredRoutes.Add($mi_139_219_16_nexthop_internet)
    $requiredRoutes.Add($mi_141_251_16_nexthop_internet)
    $requiredRoutes.Add($mi_146_147_16_nexthop_internet)
    $requiredRoutes.Add($mi_147_243_16_nexthop_internet)
    $requiredRoutes.Add($mi_150_171_16_nexthop_internet)
    $requiredRoutes.Add($mi_150_242_48_22_nexthop_internet)
    $requiredRoutes.Add($mi_157_54_15_nexthop_internet)
    $requiredRoutes.Add($mi_157_56_14_nexthop_internet)
    $requiredRoutes.Add($mi_157_60_16_nexthop_internet)
    $requiredRoutes.Add($mi_167_220_16_nexthop_internet)
    $requiredRoutes.Add($mi_168_61_16_nexthop_internet)
    $requiredRoutes.Add($mi_168_62_15_nexthop_internet)
    $requiredRoutes.Add($mi_191_232_13_nexthop_internet)
    $requiredRoutes.Add($mi_192_32_16_nexthop_internet)
    $requiredRoutes.Add($mi_192_48_225_24_nexthop_internet)
    $requiredRoutes.Add($mi_192_84_159_24_nexthop_internet)
    $requiredRoutes.Add($mi_192_84_160_23_nexthop_internet)
    $requiredRoutes.Add($mi_192_100_102_24_nexthop_internet)
    $requiredRoutes.Add($mi_192_100_103_24_nexthop_internet)
    $requiredRoutes.Add($mi_192_197_157_24_nexthop_internet)
    $requiredRoutes.Add($mi_193_149_64_19_nexthop_internet)
    $requiredRoutes.Add($mi_193_221_113_24_nexthop_internet)
    $requiredRoutes.Add($mi_194_69_96_19_nexthop_internet)
    $requiredRoutes.Add($mi_194_110_197_24_nexthop_internet)
    $requiredRoutes.Add($mi_198_105_232_22_nexthop_internet)
    $requiredRoutes.Add($mi_198_200_130_24_nexthop_internet)
    $requiredRoutes.Add($mi_198_206_164_24_nexthop_internet)
    $requiredRoutes.Add($mi_199_60_28_24_nexthop_internet)
    $requiredRoutes.Add($mi_199_74_210_24_nexthop_internet)
    $requiredRoutes.Add($mi_199_103_90_23_nexthop_internet)
    $requiredRoutes.Add($mi_199_103_122_24_nexthop_internet)
    $requiredRoutes.Add($mi_199_242_32_20_nexthop_internet)
    $requiredRoutes.Add($mi_199_242_48_21_nexthop_internet)
    $requiredRoutes.Add($mi_202_89_224_20_nexthop_internet)
    $requiredRoutes.Add($mi_204_13_120_21_nexthop_internet)
    $requiredRoutes.Add($mi_204_14_180_22_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_135_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_179_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_181_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_188_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_195_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_196_23_nexthop_internet)
    $requiredRoutes.Add($mi_204_79_252_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_152_18_23_nexthop_internet)
    $requiredRoutes.Add($mi_204_152_140_23_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_192_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_194_23_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_197_24_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_198_23_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_200_21_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_208_20_nexthop_internet)
    $requiredRoutes.Add($mi_204_231_236_24_nexthop_internet)
    $requiredRoutes.Add($mi_205_174_224_20_nexthop_internet)
    $requiredRoutes.Add($mi_206_138_168_21_nexthop_internet)
    $requiredRoutes.Add($mi_206_191_224_19_nexthop_internet)
    $requiredRoutes.Add($mi_207_46_16_nexthop_internet)
    $requiredRoutes.Add($mi_207_68_128_18_nexthop_internet)
    $requiredRoutes.Add($mi_208_68_136_21_nexthop_internet)
    $requiredRoutes.Add($mi_208_76_44_22_nexthop_internet)
    $requiredRoutes.Add($mi_208_84_21_nexthop_internet)
    $requiredRoutes.Add($mi_209_240_192_19_nexthop_internet)
    $requiredRoutes.Add($mi_213_199_128_18_nexthop_internet)
    $requiredRoutes.Add($mi_216_32_180_22_nexthop_internet)
    $requiredRoutes.Add($mi_216_220_208_20_nexthop_internet)

    return $requiredRoutes
}

function VerifyRouteTable {
    param (
        $subnet
    )
        $result = @{ 
            routes = New-Object "$NScollections.List``1[$NSnetworkModels.PSRoute]"
            hasRouteTable = $false
            success = $false 
        }
        
        Write-Host("Verifying Route table for subnet '{0}'."-f $subnet.Name)

        $requiredRoutes = RequiredRoutes $subnet
        $routeTable = LoadRouteTable $subnet
        If(
            $null -ne $routeTable
          )
        {
            $result['hasRouteTable'] = $true
            $hasCompatibleRoutes = $true

            Write-Host("Verifying Route table '{0}'." -f $routeTable.Name)

            ForEach($route in $routeTable.Routes)
            {
                $isCompatible = $true
                ForEach($requiredRoute in $requiredRoutes)
                {
                    If(ContainsCidr -cidrRangeA $requiredRoute.AddressPrefix -cidrRangeB $route.AddressPrefix)
                    {
                        $isCompatible = $requiredRoute.NextHopType -eq $route.NextHopType
                        If(-not $isCompatible)
                        {
                            break
                        }
                    }
                }
                If($isCompatible)
                {
                    $result.routes.Add($route)
                }
                Else
                {
                    $hasCompatibleRoutes = $false
                }
            }

            ForEach($requiredRoute in $requiredRoutes)
            {
                $isContained = $false
                ForEach($route in $routeTable.Routes)
                {
                    If(ContainsCidr -cidrRangeA $route.AddressPrefix -cidrRangeB $requiredRoute.AddressPrefix)
                    {
                        $isContained = $requiredRoute.NextHopType -eq $route.NextHopType
                        If($isContained)
                        {
                            break
                        }
                    }
                }
                If(-not $isContained)
                {
                    $result.routes.Add($requiredRoute)
                    $hasCompatibleRoutes = $false
                }
            }

            $result['success'] = $result['hasRouteTable'] -and $hasCompatibleRoutes
        }       
        Else
        {
            $result['success'] = $false
            $result['hasRouteTable'] = $false
            $result.routes = $requiredRoutes
        }

        If($true -eq $result['success'])
        {
            Write-Host "Passed Validation - Route table." -ForegroundColor Green
        }
        Else
        {
            If($true -eq $result['hasRouteTable'])
            {
                Write-Host "Warning - Route table needs modifications." -ForegroundColor Yellow
            }
            Else
            {
                Write-Host "Warning - There is no route table on the subnet." -ForegroundColor Yellow
            }
        }
        
        return $result
}


function PrepareServiceEndpoints
{
    param($subnet)
    Write-Host "Removing service endpoints."
    $subnet.ServiceEndpoints.Clear()
}

function PrepareServiceDelegation
{
    param($subnet)
    Write-Host "Adding Service Delegation"
    Try
    {
        $provissioingState = Add-AzDelegation -ServiceName "Microsoft.Sql/managedInstances" -Subnet $subnet -Name 'ServiceDelegation'
        if($provissioingState){
            Write-Host "Provissioning State $($provissioingState.ProvisioningState)"
        }
    }
    Catch
    {
        Write-Host "Failed: $_" -ForegroundColor Red
    }
    
}
function PrepareNSG
{
    param(
        $nsgVerificationResult,
        $virtualNetwork,   
        $subnet
    )
    Write-Host "Creating Network security group."
    $networkSecurityGroupName = "nsgManagedInstance" + (Get-Random -Maximum 1000)
    $securityRules = $nsgVerificationResult['failedSecurityRules']
    $inboundRulePriority = 0
    $outboundRulePriority = 0

    ForEach($securityRule in $nsgVerificationResult['failedSecurityRules']){
        If($securityRule.Direction -eq "Inbound") {
            $inboundRulePriority = $securityRule.Priority
        }
        Else{
            $outboundRulePriority = $securityRule.Priority
        }
    }

    ForEach($nsgRule in $nsgVerificationResult['nsgSecurityRules']){
        If($nsgRule.Direction -eq "Inbound"){
            if($nsgRule.Priority -lt $inboundRulePriority) {
                $inboundRulePriority += 10
                $nsgRule.Priority = $inboundRulePriority
            }
        }
        Else{
            if($nsgRule.Priority -lt $outboundRulePriority) {
                $outboundRulePriority += 10
                $nsgRule.Priority = $outboundRulePriority
            }
        }
        $securityRules.Add($nsgRule)
    }

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

function PrepareRouteTable
{
    param(
        $routeTableVerificationResult,
        $virtualNetwork,   
        $subnet
    )
    Write-Host "Creating Route table."
    $routeTableName = "rtManagedInstance" + (Get-Random -Maximum 1000)
    $routes = $routeTableVerificationResult['routes']

    Try
    {
        $routeTable = New-AzRouteTable -Name $routeTableName -ResourceGroupName $virtualNetwork.ResourceGroupName -Location $virtualNetwork.Location -Route $routes
    }
    Catch
    {
        Write-Host "Failed: $_" -ForegroundColor Red
    }

    Write-Host "Associating Route table."
    $subnet.RouteTable = $routeTable
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

VerifySubnet $subnet
$isOkServiceDelegation = VerifyServiceDelegation $subnet
$isOkServiceEndpoints = VerifyServiceEndpoints $subnet
$nsgVerificationResult = VerifyNSG $subnet
$isOkNSG = $nsgVerificationResult['success']
$routeTableVerificationResult = VerifyRouteTable $subnet
$hasRouteTable = $routeTableVerificationResult['hasRouteTable']
$isOkRouteTable = $routeTableVerificationResult['success']
$isValid = $isOkServiceEndpoints -and $isOkNSG -and $isOkRouteTable -and $isOkServiceDelegation

If($isValid -ne $true)
{
    Write-Host
    Write-Host("----------  To prepare the virtual network subnet for Managed Instance this script will: --------------- ")  -ForegroundColor Yellow    
    Write-Host
    If($isOkServiceEndpoints -ne $true)
    {
        Write-Host "[Endpoints] Remove all service endpoints." -ForegroundColor Yellow
    }    
    If($isOkNSG -ne $true)
    {
        Write-Host "[NSG] Create a copy of assoicated Network security group and add security rules to:" -ForegroundColor Yellow
        ForEach($rule in $nsgVerificationResult['failedSecurityRules']){
            Write-Host ("[NSG] -"+$rule.Description) -ForegroundColor Yellow
        }
        Write-Host "[NSG] Associate newly created Network security group to subnet." -ForegroundColor Yellow
    }  
    If($isOkRouteTable -ne $true)
    {
        If($hasRouteTable -eq $true)
        {
            Write-Host "[UDR] Create modified copy of associated Route table." -ForegroundColor Yellow
        }
        Else
        {
            Write-Host "[UDR] Create Route table with required routes." -ForegroundColor Yellow
        }
        Write-Host "[UDR] Associate newly created Route table to subnet." -ForegroundColor Yellow
    }
    If($isOkServiceDelegation -ne $true)
    {
        Write-Host "[Service Delegation] Add Microsoft.Sql/managedInstances as a service delegation for subnet" -ForegroundColor Yellow
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
        If($isOkServiceEndpoints -ne $true)
        {
            PrepareServiceEndpoints $subnet
        }
            
        If($isOkNSG -ne $true)
        {
            PrepareNSG $nsgVerificationResult $virtualNetwork $subnet
        }  

        If($isOkRouteTable -ne $true)
        {
            PrepareRouteTable $routeTableVerificationResult $virtualNetwork $subnet
        }
           
        If($isOkNSG -ne $true)
        {
            PrepareNSG $nsgVerificationResult $virtualNetwork $subnet
        }

        If($isOkServiceDelegation -ne $true)
        {
            PrepareServiceDelegation $subnet
        }
        SetVirtualNetwork $virtualNetwork

        Write-Host
        Write-Host "Subnet prepared for the Managed Instance." -ForegroundColor Green        
        Write-Host "https://portal.azure.com/#create/Microsoft.SQLManagedInstance"
    }
    Else
    {
        Write-Host
        Write-Host "Subnet preparation canceled." -ForegroundColor Yellow
    }

}
Else
{
    Write-Host
    Write-Host "Subnet is already prepared." -ForegroundColor Green
    Write-Host "https://portal.azure.com/#create/Microsoft.SQLManagedInstance"
}
