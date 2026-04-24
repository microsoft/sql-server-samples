# Assessment of SQL Server on Azure Virtual Machines

With SQL Assessment cmdlets, you can assess an instance of SQL Server on an Azure VM not only as on-premises SQL Server, but also with rules that are specific to Azure environments.

To use such rules, do the following:

1. Make sure that both the [Azure PowerShell module](https://aka.ms/AAbdhwk) and the [Az.ResourceGraph module](https://www.powershellgallery.com/packages/Az.ResourceGraph) are installed.

2. [Sign in with Azure PowerShell](https://aka.ms/AAbdogm) before invoking SQL Assessment against SQL Server on an Azure VM.

**NOTE:** It is possible to use Azure account connection persisted between PowerShell sessions, i.e. invoke **Connect-AzAccount** in one session and omit this command later. However, in such a scenario, SQL Assessment cmdlets need the **Az.ResourceGraph** module to be imported explicitly by running **Import-Module Az.ResourceGraph**.

## Performing Assessment

The following example shows how to invoke assessment for SQL Server on an Azure VM instance. Active Azure subscription connection enables rules that are specific to SQL Server on Azure VMs&mdash;**AzSqlVmSize** in this example:

1. Invoke the [Connect-AzAccount](https://docs.microsoft.com/powershell/module/az.accounts/connect-azaccount) cmdlet that establishes connection with the Azure account to get data from Azure Resource Graph.

    ```PowerShell
    Connect-AzAccount
    ```

2. [Optional step] After invoking **Connect-AzAccount**, you can run the [Set-AzContext](https://docs.microsoft.com/powershell/module/az.accounts/set-azcontext) cmdlet.

    ```PowerShell
    Set-AzContext My-Pay-As-You-Go
    ```

3. [Optional step] Invoke the [Get-Credential](https://docs.microsoft.com/powershell/module/microsoft.powershell.security/get-credential) cmdlet that creates a credential object for the specified user name and password.

   ```PowerShell
   $cred = Get-Credential
   ```

4. Select SQL Server objects to assess. For example, the following command gets a SQL Server instance.

     ```PowerShell
    $target = Get-SqlInstance -ServerInstance "Computer002\InstanceName" -Credential $cred
    ```

    `-Credential` is an optional parameter and can be omitted.

5. Run the [Invoke-SqlAssessment](https://docs.microsoft.com/powershell/module/sqlserver/invoke-sqlassessment) cmdlet that builds a check list for each input object, runs through the list, and returns best practice recommendations.

    ```PowerShell
    Invoke-SqlAssessment $target
    ```

As a result, you would get an output similar to the following one.

```
   TargetPath : Server[@Name='ContosoAzureSQL']

Sev. Message                                                            Check ID              Origin
---- -------                                                            --------              ------
Medi Amount of single use plans in cache is high (100%). Consider       PlansUseRatio         Microsoft Ruleset 0.1.202
     enabling the Optimize for ad hoc workloads setting on heavy OLTP
     ad-hoc workloads to conserve resources
Low  Use memory optimized virtual machine sizes for the best            AzSqlVmSize           Microsoft Ruleset 0.1.202
     performance of SQL Server workloads
```

Here, **Server[@Name='ContosoAzureSQL']** shows the server name that hosts the assessed SQL Server instance, the **Sev.** column shows the severity level, which can be *Information*, *Medium*, *Low*, or *High*, in the **Message** column, the actual best practice recommendations are shown, the **Check ID** column shows the rule name, and the **Origin** column displays the ruleset name and version.

In this example, the **AzSqlVmSize** rule is applicable solely to the SQL Server deployed on an Azure VM; it checks whether the size of the VM is [memory-optimized](https://docs.microsoft.com/azure/virtual-machines/sizes-memory) or not.