---
services: Azure Arc enabled SQL Server
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 12/08/2020
---

# Running the script using Cloud Shell

Use the following steps to migrate your existing SQL Server - Azure Arc resources from Microsoft.AzureData namespace to Microsoft.AzureArcData namespace.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to the shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/migrate-to-azure-arc-data.ps1 -o migrate-to-azure-arc-data.ps1
    ```

3. Run the script.  

    ```console
   ./migrate-to-azure-arc-data.ps1
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.
> - The script will prompt for the resource group name and print a message when migration is completed.
