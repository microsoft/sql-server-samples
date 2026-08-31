# Overview

This script installs a pay-as-you-go SQL Server instance on your machine and automatically connects it to Azure using a downloaded SQL Server media.

# Prerequisites

- You have met the [onboarding prerequisites](https://learn.microsoft.com/sql/sql-server/azure-arc/prerequisites).
- You have downloaded a SQL Server image file from the workspace provided by Microsoft technical support. To obtain it, open a support request using the "Get SQL Installation Media" subcategory and specify the desired version and edition. 
- You are logged in to the machine with an administrator account. 
- If you are installing SQL Server on Windows Server 2016, you have a secure TLS configuration as described below.


# Mitigating the TLS version issue on Windows Server 2016

When running the script on Windows Server 2016, the OS may be configured with a TLS version that does not meet the Azure security requirements. You need to enable strong TLS versions (TLS 1.2 and 1.3) when they are available, while still supporting older TLS versions (1.0 and 1.1) when TLS 1.2 and 1.3 are unavailable. You need to also disable versions SSL2 and SSL3, which are insecure.

To see if you need to make the change, run the command below from an elevated PowerShell prompt.
```PowerShell
[Net.ServicePointManager]::SecurityProtocol
```

If the result is `SSL3, Tls`, you need to fix the TLS version by running the following commands.

```PowerShell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord 
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord 
```

After running these commands, reboot the machine (in case currently-running applications were referencing previous values). To verify that the changes were applied correctly, run this command again: 

```PowerShell
[Net.ServicePointManager]::SecurityProtocol
```
The result should be `Tls, Tls11, Tls12, Tls13`

# Downloading the script

To download the script to your current folder run:

```console
curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/install-payg-sql-server/install-payg-sql-server.ps1 -o install-payg-sql-server.ps1
```

# Launching the script

The script must be run in an elevated PowerShell session. It accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|-AzureSubscriptionId|subscription_id|Required: Subscription id that will contain the Arc-enabled machine and Arc-enable SQL Server resources. That subscription will be billed for SQL Server software using a pay-as-you-go method. |
|-AzureResourceGroup |resource_group_name|Required: Resource group that will contain the Arc-enabled machine and Arc-enable SQL Server resource.|
|-AzureRegion |region name| Required: the region to store the machuine and SQL Server meta-data. |
|-SqlServerInstanceName | name of the instance|Optional: the machine name will be used if not specified|
|-SqlServerAdminAccounts | SQL Server admin accounts | Optional. By default "BUILTIN\ADMINISTRATORS" will be used.|
|-SqlServerSvcAccount| SQL Server services account |Optional. By default "NT AUTHORITY\NETWORK SERVICE" will be used.|
|-SqlServerSvcPassword| SQL Server service account password| Required if a custom service account is specified.|
|-AgtServerSvcAccount|SQL Agent service account|Optional. By default "NT AUTHORITY\NETWORK SERVICE" will be used.|
|-AgtServerSvcPassword|SQL Agent service account password|Required if a custom service account is specified.|
|-IsoFolder|Folder path|Required. The folder containing the files downloaded from the workspace.|
|-Proxy|HTTP proxy URL|Optional. Needed if your networks is configured with an HTTP proxy.|

# Example

The following command installs a SQL Server instance from the Downloads folder, connects it to subscription ID `<sub_id>`, resource group `<resource_group>` in the West US region, and configures it with LicenseType=PAYG. It uses the default admin and service accounts, and uses a direct connection to Azure.

```PowerShell
.\install-payg-sql-server.ps1 -AzureSubscriptionId <sub_id> -AzureResourceGroup <resource_group> -AzureRegion westus -IsoFolder C:\Users\[YourUsername]\Downloads

```
