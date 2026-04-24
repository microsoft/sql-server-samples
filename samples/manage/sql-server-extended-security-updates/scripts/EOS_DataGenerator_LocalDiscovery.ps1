<#
   Discovers local SQL Server instance names.
   Run the following command: .\EOS_DataGenerator_LocalDiscovery.ps1

   Disclaimer
   The sample scripts are not supported under any Microsoft standard support program or service.
   The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including,
   without limitation, any implied warranties of merchantability or of fitness for a particular purpose.
   The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
   In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable
   for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of
   business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation,
   even if Microsoft has been advised of the possibility of such damages.
#>

Clear-Variable -name subscriptionId

$CSVfilename = Read-Host "Output file will be saved in the current script path. Enter a file name for the CSV output"

If ( [string]::IsNullOrEmpty($CSVfilename) ) {
    Throw "Parameter missing: Output file"
} Else {
    If ($CSVfilename -notlike "*.csv") { $CSVfilename = $CSVfilename + ".csv" }

    $scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
    $CSVfilename = $scriptFolder + "\" + $CSVfilename
    Write-Host -ForegroundColor Green "Saving output to file $CSVfilename. Please wait..."
}

$IsAzureVM = Read-Host "Is this an Azure Virtual Machine? (Y/N)"

If ( $IsAzureVM -eq "Y" ) {

    $subscriptionName = Read-Host "Enter your Azure subscription name"

    Write-Host -ForegroundColor Yellow "`nChecking for latest version of Azure PS..."
    Try {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
        Import-Module Az
    }
    Catch {
        # Error if not connected
        Throw "Could not install Azure PS module"
        Break
    }

    Write-Host -ForegroundColor Yellow "Connecting to Azure account..."
    Try {
        Connect-AzAccount -Subscription $subscriptionName
    }
    Catch {
        # Error if not installed
        Throw "Could not connect to Azure account"
        Break
    }

    Write-Host -ForegroundColor Yellow "Selecting subscription $subscriptionName..."
    Try {
        $AzureSubscription = Get-AzSubscription -SubscriptionName $subscriptionName
        $IsAzureVM = Get-AzVM -Name $env:computername

        $subscriptionId = $AzureSubscription.SubscriptionId
        $resourceGroup = $IsAzureVM.ResourceGroupName
        $IsAzureVMName = $IsAzureVM.Name
        $IsAzureVMOS = (Get-WmiObject Win32_OperatingSystem).Caption

        If ($IsAzureVMOS -like "*2008 R2*"){
            $OutVersion = '2008 R2'}
        Elseif ($IsAzureVMOS -like "*2008*"){
            $OutVersion = '2008'}
        Elseif ($IsAzureVMOS -like "*2012 R2*"){
            $OutVersion = '2012 R2'}
        Elseif ($IsAzureVMOS -like "*2012*"){
            $OutVersion = '2012'}
        Elseif ($IsAzureVMOS -like "*2016*"){
            $OutVersion = '2016'}
        Elseif ($IsAzureVMOS -like "*2019*"){
            $OutVersion = '2019'}

        $IsAzureVMOS = $OutVersion
    }
    Catch {
        Throw "Could not get Azure VM information"
        Break
    }
}

Function Get-SQLInstance {

    Write-Host -ForegroundColor Yellow "`nLooping SQL Server instances on $env:computername..."

    $services = Get-Service -Computer $env:computername -DisplayName "SQL Server (*)"

    # Remove MSSQL$ qualifier to get instance name
    Try {
        $ServerNames = $services.Name | ForEach-Object {$env:computername + "\" + ($_).Replace("MSSQL`$","")}
        If ($ServerNames -like "*MSSQLSERVER") { $ServerNames = $env:computername }
    }
    Catch {
        # Error if none found
        Throw "No SQL Server instances found"
        Break
    }
    Return $ServerNames
}

Function Get-Info {
    [CmdletBinding()]
    Param( [Parameter(Mandatory = $TRUE, ValueFromPipeline = $TRUE)] [String] $ServerName,
        [String] $subscriptionId,
        [String] $resourceGroup,
        [String] $IsAzureVMName,
        [String] $IsAzureVMOS )

    Process {

            Write-Host "`nConnecting to $ServerName..."

            # Get SQL Server instance's data
            Try {
                $sqlconn = New-Object System.Data.SqlClient.SqlConnection("server=$ServerName;Trusted_Connection=true");
                $sqlconn.Open()
            }
            Catch {
                # Error if no connection
                Throw "Could not connect to $ServerName"
                Continue
            }

            Try {
                $query = "SELECT SERVERPROPERTY('Edition') AS Edition, SERVERPROPERTY('ProductVersion') AS Version;"
                $sqlcmd = New-Object System.Data.SqlClient.SqlCommand ($query, $sqlconn);
                $sqlcmd.CommandTimeout = 0;
                $dr = $sqlcmd.ExecuteReader();
            }
            Catch {
                # Error if not able to execute
                Throw "Could not execute query in $ServerName"
                Continue
            }

            Write-Host "|- Querying $ServerName..."

            While ( $dr.Read() ) {
             $SQLEdition = $dr.GetValue(0);
             $Version = $dr.GetValue(1);
            }

            $Version = $Version.Substring(0,4);
            $SQLEdition = $SQLEdition.split(' ')[0];

            If ($Version -eq "10.0"){
                $OutVersion = '2008'}
            Elseif ($Version -eq "10.5"){
                $OutVersion = '2008R2'}
            Elseif ($Version -eq "11.0"){
                $OutVersion = '2012'}
            Elseif ($Version -eq "12.0"){
                $OutVersion = '2014'}
            Elseif ($Version -eq "13.0"){
                $OutVersion = '2016'}
            Elseif ($Version -eq "14.0"){
                $OutVersion = '2017'}
            Elseif ($Version -eq "15.0"){
                $OutVersion = '2019'}
            Else {
                $OutVersion = 'Unknown'}

            $Version = $OutVersion
            $dr.Close()
            $sqlconn.Close()

            #Get processors information
            $CPU = Get-WmiObject -ComputerName $env:computername -class Win32_Processor

            #Get Computer model information
            $Manufacturer = (Get-WmiObject -ComputerName $env:computername -class Win32_ComputerSystem).Manufacturer

            If ( -not [string]::IsNullOrEmpty($subscriptionId)){
                $HostType = 'Azure Virtual Machine'}
            Elseif ($Manufacturer -like "Microsoft*"){
                $HostType = 'Virtual Machine'}
            Elseif ($Manufacturer -like "VMWare*"){
                $HostType = 'Virtual Machine'}
            Else {
                $HostType = 'Physical Server'}

            #Reset number of cores and use count for the CPUs counting
            $CPUs = 0
            $Cores = 0

            ForEach ( $Processor in $CPU ) {
                $CPUs = $CPUs + 1

                #count the total number of cores
                $Cores = $Cores + $Processor.NumberOfCores
            }

            If ( [string]::IsNullOrEmpty($subscriptionId) ) {
                $InfoRecord = New-Object -TypeName PSObject -Property @{
                    Name = $ServerName;
                    HostType = $HostType;
                    Cores = $Cores;
                    Edition = $SQLEdition;
                    Version = $Version;
                    }
            } Else {
                $InfoRecord = New-Object -TypeName PSObject -Property @{
                    Name = $ServerName;
                    HostType = $HostType;
                    Cores = $Cores;
                    Edition = $SQLEdition;
                    Version = $Version;
                    SubscriptionId = $subscriptionId;
                    ResourceGroup = $resourceGroup;
                    AzureVmName = $IsAzureVMName;
                    AzureVmOS = $IsAzureVMOS;
                    }
            }

            Write-Output $InfoRecord
    }
}

#Loop through the server list and get information about SQL Server instances
If ( [string]::IsNullOrEmpty($subscriptionId) ) {
        Get-SQLInstance | Foreach-Object {Get-Info $_ $subscriptionId $resourceGroup $IsAzureVMName $IsAzureVMOS} `
        | Select-Object "name", "version", "edition", "cores", "hostType" `
        | ConvertTo-Csv -NoTypeInformation `
        | % { $_ -Replace '"', ""} `
        | Out-File -FilePath $CSVfilename #-Encoding UTF8 #-NoClobber #-Append
} Else {
        Get-SQLInstance | Foreach-Object {Get-Info $_ $subscriptionId $resourceGroup $IsAzureVMName $IsAzureVMOS} `
        | Select-Object "name", "version", "edition", "cores", "hostType", "subscriptionId", "resourceGroup", "azureVmName", "azureVmOS" `
        | ConvertTo-Csv -NoTypeInformation `
        | % { $_ -Replace '"', ""} `
        | Out-File -FilePath $CSVfilename -Encoding UTF8 #-NoClobber #-Append
}

Write-Host -ForegroundColor Yellow "`nDone!"