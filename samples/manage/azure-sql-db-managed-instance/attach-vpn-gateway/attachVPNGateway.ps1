$parameters = $args[0]
$scriptUrlBase = $args[1]

$subscriptionId = $parameters['subscriptionId']
$environmentName = $parameters['environmentName']
$resourceGroupName = $parameters['resourceGroupName']
$virtualNetworkName = $parameters['virtualNetworkName']
$certificateNamePrefix = $parameters['certificateNamePrefix']
$clientCertificatePassword = $parameters['clientCertificatePassword'] #used only when certificates are created using openssl

if ($environmentName -eq '' -or ($null -eq $environmentName)) {
    $environmentName = 'AzureCloud'
    Write-Host "Environment: AzureCloud." -ForegroundColor Green
}

if ($clientCertificatePassword -eq '' -or ($null -eq $clientCertificatePassword)) {
    $clientCertificatePassword = 'S0m3Str0nGP@ssw0rd'
}

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
    }
    else {
        Write-Host "Module Az imported." -ForegroundColor Green        
    }
}

function EnsureLogin {
    param (
        $environmentName
    )
    $context = Get-AzContext
    If ($null -eq $context.Subscription) {
        Write-Host "Sign-in..."
        If ($null -eq (Connect-AzAccount -Environment $environmentName -ErrorAction SilentlyContinue -ErrorVariable Errors)) {
            Write-Host ("Sign-in failed: {0}" -f $Errors[0].Exception.Message) -ForegroundColor Red
            Break
        }
    }
    Write-Host "Sign-in successful." -ForegroundColor Green
}

function SelectSubscriptionId {
    param (
        $subscriptionId
    )
    Write-Host "Selecting subscription '$subscriptionId'..."
    $context = Get-AzContext
    If ($context.Subscription.Id -ne $subscriptionId) {
        Try {
            $currentSubscriptionId = $context.Subscription.Id
            Write-Host "Switching subscription $currentSubscriptionId to '$subscriptionId'." -ForegroundColor Green
            Select-AzSubscription -SubscriptionId $subscriptionId -ErrorAction Stop | Out-null
        }
        Catch {
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
    $virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName -ErrorAction SilentlyContinue
    $id = $virtualNetwork.Id
    If ($null -ne $id) {
        Write-Host "Virtual network with id $id is loaded." -ForegroundColor Green
        If ($virtualNetwork.VirtualNetworkPeerings.Count -gt 0) {
            Write-Host "Virtual network is loaded, but it should not have peerings." -ForegroundColor Red
        }
        return $virtualNetwork
    }
    else {
        Write-Host "Virtual network $virtualNetworkName cannot be found." -ForegroundColor Red
        Break
    }
}

function SetVirtualNetwork {
    param($virtualNetwork)

    Write-Host "Applying changes to the virtual network."
    Try {
        Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork -ErrorAction Stop | Out-Null
    }
    Catch {
        Write-Host "Failed to configure Virtual Network: $_" -ForegroundColor Red
    }
}

function ConvertCidrToUint32Array {
    param($cidrRange)
    $cidrRangeParts = $cidrRange.Split("/")
    $ipParts = $cidrRangeParts[0].Split(".")
    $ipnum = ([Convert]::ToUInt32($ipParts[0]) -shl 24) -bor `
    ([Convert]::ToUInt32($ipParts[1]) -shl 16) -bor `
    ([Convert]::ToUInt32($ipParts[2]) -shl 8) -bor `
        [Convert]::ToUInt32($ipParts[3])

    $maskbits = [System.Convert]::ToInt32($cidrRangeParts[1])
    $mask = 0xffffffff
    $mask = $mask -shl (32 - $maskbits)
    $ipstart = $ipnum -band $mask
    $ipend = $ipnum -bor ($mask -bxor 0xffffffff)
    return @($ipstart, $ipend)
}

function ConvertUInt32ToIPAddress {
    param($uint32IP)
    $v1 = $uint32IP -band 0xff
    $v2 = ($uint32IP -shr 8) -band 0xff
    $v3 = ($uint32IP -shr 16) -band 0xff
    $v4 = ($uint32IP -shr 24)
    return "$v4.$v3.$v2.$v1"
}

function CalculateNextAddressPrefix {
    param($virtualNetwork, $prefixLength)
    Write-Host "Calculating address prefix with length $prefixLength..."
    $startIPAddress = 0
    ForEach ($addressPrefix in $virtualNetwork.AddressSpace.AddressPrefixes) {
        $endIPAddress = (ConvertCidrToUint32Array $addressPrefix)[1]
        If ($endIPAddress -gt $startIPAddress) {
            $startIPAddress = $endIPAddress
        }
    }
    $startIPAddress += 1
    $addressPrefixResult = (ConvertUInt32ToIPAddress $startIPAddress) + "/" + $prefixLength
    Write-Host "Using address prefix $addressPrefixResult." -ForegroundColor Green
    return $addressPrefixResult
}

function CalculateVpnClientAddressPoolPrefix {
    param($gatewaySubnetPrefix)
    Write-Host "Calculating VPN client address pool prefix."
    If ($gatewaySubnetPrefix.StartsWith("10.")) {
        return "192.168.0.0/24"
    }
    else {
        return "172.16.0.0/24"
    }

}

function CreateCerificateWindows() {
    $certificate = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
        -Subject ("CN=$certificateNamePrefix" + "P2SRoot") -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 -KeyLength 2048 `
        -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

    $certificateThumbprint = $certificate.Thumbprint

    New-SelfSignedCertificate -Type Custom -DnsName ($certificateNamePrefix + "P2SChild") -KeySpec Signature `
        -Subject ("CN=$certificateNamePrefix" + "P2SChild") -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 -KeyLength 2048 `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -Signer $certificate -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") | Out-null
    
    [Convert]::ToBase64String((Get-Item cert:\currentuser\my\$certificateThumbprint).RawData)
}

function CreateCerificateOpenSsl() {   
    $dn = "CN=$certificateNamePrefix" + "P2SRoot"
    ipsec pki --gen --outform pem > caKey.pem
    ipsec pki --self --in caKey.pem --dn $dn --ca --outform pem > caCert.pem

    $dn = $certificateNamePrefix + "P2SChild"
    ipsec pki --gen --outform pem > "$($dn)Key.pem"
    ipsec pki --pub --in "$($dn)Key.pem" --outform pem > "$($dn)PubKey.pem"
    ipsec pki --issue --in "$($dn)PubKey.pem" --cacert caCert.pem --cakey caKey.pem --dn "CN=$($dn)" --san $dn --flag clientAuth --outform pem > "$($dn)Cert.pem"
    
    openssl pkcs12 -in "$($dn)Cert.pem" -inkey "$($dn)Key.pem" -certfile caCert.pem -export -out "$($dn).p12" -password "pass:$($clientCertificatePassword)"
    #openssl pkcs12 -in "$($dn).p12" -password "pass:$($clientCertificatePassword)" -nocerts -out "$($dn)PrivateKey.pem" -nodes
    #openssl pkcs12 -in "$($dn).p12" -password "pass:$($clientCertificatePassword)" -nokeys -out "$($dn)PublicCert.pem" -nodes

    $publicRootCertData = openssl x509 -in caCert.pem -outform pem 
    $publicRootCertData = $publicRootCertData -replace "-----BEGIN CERTIFICATE-----", ""
    $publicRootCertData = $publicRootCertData -replace "-----END CERTIFICATE-----", ""
    [string]::Join("", $publicRootCertData.Split())
}

function CreateCertificate() {
    Write-Host "Creating certificate."
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        return CreateCerificateWindows
    }
    else {
        return CreateCerificateOpenSsl
    }
}

VerifyPSVersion
EnsureAzModule
EnsureLogin -environmentName $environmentName
SelectSubscriptionId -subscriptionId $subscriptionId
$virtualNetwork = LoadVirtualNetwork -resourceGroupName $resourceGroupName -virtualNetworkName $virtualNetworkName

$subnets = $virtualNetwork.Subnets.Name

$gatewaySubnetName = "GatewaySubnet"

If ($false -eq $subnets.Contains($gatewaySubnetName)) {
    Write-Host "$gatewaySubnetName is not one of the subnets in $subnets" -ForegroundColor Yellow
    $gatewaySubnetPrefix = CalculateNextAddressPrefix $virtualNetwork 28
    Write-Host "Creating subnet $gatewaySubnetName ($gatewaySubnetPrefix) in the virtual network ..." -ForegroundColor Green

    $virtualNetwork.AddressSpace.AddressPrefixes.Add($gatewaySubnetPrefix)
    Add-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetName -VirtualNetwork $virtualNetwork -AddressPrefix $gatewaySubnetPrefix | Out-Null

    SetVirtualNetwork $virtualNetwork
    Write-Host "Added subnet $gatewaySubnetName into virtual network." -ForegroundColor Green
}
else {
    Write-Host "The subnet $gatewaySubnetName exists in the virtual network." -ForegroundColor Green
    $gatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetName -VirtualNetwork $virtualNetwork
    $gatewaySubnetPrefix = $gatewaySubnet.AddressPrefix[0]
}

$vpnClientAddressPoolPrefix = CalculateVpnClientAddressPoolPrefix $gatewaySubnetPrefix
$publicRootCertData = CreateCertificate

Write-Host

# Start the deployment
Write-Host "Starting deployment..."
Write-Host "Deployment will take about 1h." -ForegroundColor Yellow

$templateParameters = @{
    location                   = $virtualNetwork.Location    
    virtualNetworkName         = $virtualNetworkName
    gatewaySubnetPrefix        = $gatewaySubnetPrefix
    vpnClientAddressPoolPrefix = $vpnClientAddressPoolPrefix
    publicRootCertData         = $publicRootCertData
}

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri ($scriptUrlBase + '/azuredeploy.json?t=' + [DateTime]::Now.Ticks) -TemplateParameterObject $templateParameters

Write-Host "Deployment completed."
