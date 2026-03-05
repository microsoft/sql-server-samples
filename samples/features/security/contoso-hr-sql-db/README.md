# Contoso HR Security Demo 

This set of samples and demos showcases the benefits of the following features in Azure SQL Database:

- [Always Encrypted with secure enclaves](https://docs.microsoft.com/azure/azure-sql/database/always-encrypted-with-secure-enclaves-landing)

## Contents

1. [Prerequisites](#Prerequisites)
2. [Setup](#Setup)
3. [Demos](#Demos)

## Prerequisites
Before you begin you need an Azure subscription. If you don't already have an Azure subscription, you can get one for free [here](https://azure.microsoft.com/free/).

You also need to make sure the following software is installed on your machine:

1. PowerShell modules:
    1. Az version 5.6 or later. For details on how to install the Az PowerShell module, see [Install the Azure Az PowerShell module](https://docs.microsoft.com/powershell/azure/install-az-ps). To determine the version the Az module installed on your machine, run the following command from a PowerShell session.

        ```powershell
        Get-InstalledModule -Name Az
        ```

    1. Az.Attestation 0.1.8 or later. For details on how to install the Az.Attestation PowerShell module, see [Install Az.Attestation PowerShell module](https://docs.microsoft.com/azure/attestation/quickstart-powershell#install-azattestation-powershell-module). To determine the version the Az.Attestation module installed on your machine, run the following command from a PowerShell session.

        ```powershell
        Get-InstalledModule -Name Az.Attestation
        ```
    1. SqlServer version 21.1.18245 or later. For details on how to install the SqlServer PowerShell module, see [Installing or updating the SqlServer module](https://docs.microsoft.com/sql/powershell/download-sql-server-ps-module#installing-or-updating-the-sqlserver-module). To determine the version the SqlServer module installed on your machine, run the following command from a PowerShell session.

        ```powershell
        Get-InstalledModule -Name SqlServer
        ```

1. [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/templates/bicep-overview) version 0.4.63 or later. You need install Bicep and ensure it can be invoked from PowerShell. The recommended way to achieve that is to [install Bicep manually with PowerShell](https://docs.microsoft.com/azure/azure-resource-manager/templates/bicep-install?tabs=azure-powershell#manual-with-powershell).
1. [SQL Server Management Studio](https://msdn.microsoft.com/en-us/library/mt238290.aspx) - version 18.9.1 or later is recommended.

## Setup

1. Clone/download the repository.
1. Open a PowerShell session.
1. In the PowerShell session, change the directory to the setup folder within this demo's directory.
1. Run the setup.ps1 PowerShell script.
1. When prompted, enter the following information:
    1. Your Azure subscription id. To determine your subscription id, see [Find your Azure subscription](https://docs.microsoft.com/en-us/azure/media-services/latest/setup-azure-subscription-how-to?tabs=portal).
    1. The project name. The resource group containing all your demo resources will have that name. The project name will also be used as a prefix for the names of all demo resources. Please use only lowercase letters and numbers for the project name and make sure it is unique.
    1. The location - it must be the name of an Azure region that supports the [DC-series hardware generation](https://docs.microsoft.com/azure/azure-sql/database/service-tiers-vcore?tabs=azure-portal#dc-series-1) in Azure SQL Database.
    1. The username and the password of the Azure SQL database server administrator. The setup script will create the server with these admin credentials and it will later use them to connect to the server using SQL authentication for some of the setup steps.
1. When prompted, sign in to Azure. Once you sign in, the script will deploy the demo environment using the provided Bicep template, which may take a few minutes. After the deployment completes, the script performs post-deployment setup steps to configure the database and the attestation policy for Always Encrypted with secure enclaves.
1. When prompted, sign in to Azure again, to enable the SqlServer PowerShell module to connect to the database.
1. Finally, the script outputs the important information about your demo environment.
    - Database server name (`<project name>server.database.windows.net`)
    - Database name (`ContosoHR`)
    - Attestation URL (`https://<project name>attest.<region moniker>.attest.azure.net/attest/SgxEnclave`)
    - Application URL (`https://<project name>app.azurewebsites.net/`)

    Please copy and save the above information. You will need it for the demo steps.

## Demos

- [Always Encrypted with secure enclaves](always-encrypted-with-secure-enclaves/README.md)