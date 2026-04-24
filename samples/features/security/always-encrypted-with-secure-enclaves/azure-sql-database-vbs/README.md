![](../../../../manage/sql-server-extended-security-updates/media/solutions-microsoft-logo-small.png)

# Always Encrypted with VBS enclaves in Azure SQL Database - Demos

The demos in this folder showcase [Always Encrypted with secure enclaves](https://docs.microsoft.com/azure/azure-sql/database/always-encrypted-with-secure-enclaves-landing) in Azure SQL Database. The demos use the Contoso HR web application.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Setup](#setup)<br/>
[Demo 1](#demo-1) - a tour of the demo environment<br/>
[Demo 2](#demo-2) - a short demo of key benefits of secure enclaves<br/>
[Demo 3](#demo-3) - a longer demo showcasing in-place encryption and rich queries<br/>
[Cleanup](#cleanup)<br/>

## About this sample

- **Applies to:** Azure SQL Database
- **Key features:** Always Encrypted with VBS enclaves
- **Workload:** Human resources (HR) application
- **Programming Language:** C#, Transact-SQL
- **Authors:** Jakub Szymaszek, Pieter Vanhove
- **Update history:**

## Before you begin

Before you begin, you need an Azure subscription. If you don't already have an Azure subscription, you can get one for free [here](https://azure.microsoft.com/free/).

You also need to make sure the following software is installed on your machine:

1. PowerShell modules:

   1. Az version 9.3 or later. For details on how to install the Az PowerShell module, see [Install the Azure Az PowerShell module](https://docs.microsoft.com/powershell/azure/install-az-ps). To determine the version of the Az module installed on your machine, run the following command from a PowerShell session.

     ```powershell
     Get-InstalledModule -Name Az
     ```

   2. SqlServer version 22.0.49-preview or later. For details on how to install the SqlServer PowerShell module, see [Installing or updating the SqlServer module](https://docs.microsoft.com/sql/powershell/download-sql-server-ps-module#installing-or-updating-the-sqlserver-module). To determine the version the SqlServer module installed on your machine, run the following command from a PowerShell session.

     ```powershell
     Get-InstalledModule -Name SqlServer
     ```

1. [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/templates/bicep-overview) version 0.13.1 or later. You need to install Bicep and ensure it can be invoked from PowerShell. The recommended way to achieve that is to [install Bicep manually with PowerShell](https://docs.microsoft.com/azure/azure-resource-manager/templates/bicep-install?tabs=azure-powershell#manual-with-powershell).
1. [SQL Server Management Studio](https://msdn.microsoft.com/en-us/library/mt238290.aspx) - version 19 or later is recommended.

## Setup

By following the below setup steps, you will create a new resource group and deploy the following resources to your Azure subscription:
- A logical database server.
- The **ContosoHR** database with VBS enclaves enabled.
- A key vault in [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/) and a key to be used as a column master key for Always Encrypted.
- The Contoso HR web application in Azure Web Apps.

Setup steps:

1. Clone/download and unpack the repository.
1. Open a PowerShell session.
1. In the PowerShell session, change the directory to the setup folder within this demo's directory. For example, if you've unpacked the downloaded repository on a Windows machine in **C:\\**, issue the following command:

   ```powershell
   cd "C:\sql-server-samples\samples\features\security\always-encrypted-with-secure-enclaves\azure-sql-database\setup"
   ```

1. Run the **setup.ps1** PowerShell script.
1. When prompted, enter the following information:
   1. Your Azure subscription id. To determine your subscription id, see [Find your Azure subscription](https://docs.microsoft.com/azure/media-services/latest/setup-azure-subscription-how-to?tabs=portal).
   1. The project name. The resource group containing all your demo resources will have that name. The project name will also be used as a prefix for the names of all demo resources. Please use only lowercase letters and numbers for the project name and make sure it is unique.
   1. The location where you want to create the resources.
   1. The username and the password of the Azure SQL database server administrator. The setup script will create the server with these admin credentials and it will later use them to connect to the server using SQL authentication for some of the setup steps.
1. When prompted, sign in to Azure. Once you sign in, the script will deploy the demo environment using the provided Bicep template, which may take a few minutes. After the deployment completes, the script performs post-deployment setup steps to configure the database.
1. When prompted, sign in to Azure again, to enable the SqlServer PowerShell module to connect to the database.
1. Finally, the script outputs the important information about your demo environment.
   - Database server name (`<project name>server.database.windows.net`)
   - Database name (`ContosoHR`)
   - Application URL (`https://<project name>app.azurewebsites.net/`)

   Please copy and save the above information. You will need it for the demo steps.

## Demo 1

In this demo, you will take a tour of the demo environment, in which Always Encrypted with secure enclaves is already set up and sensitive data columns in the database are already encrypted.

### Prepare for the demo

Perform the below steps before each demo presentation.

1. Close all running instances of SQL Server Management Studio (SSMS).
1. Prepare a new instance of SSMS.
   1. Start SSMS.
   1. In the Connect to Server dialog:
      1. In the main page of the dialog, enter your database server name. Set **Authentication** to **Azure Active Directory – Universal with MFA**. In the **User Name** field, enter your Azure AD username. You should enter the same username, you used to sign in to Azure, when you set up your demo environment.

        ![Connect to Server](./img/ssms-connect-to-server-main-page.png)

      1. Click **Connect**.
      1. When prompted, sign in to Azure.
1. Prepare your web browser.
   1. Open a new tab in the browser and point it to Azure Portal: **https://portal.azure.com**.
   1. Sign in to Azure if prompted.
   1. In the **Search** box in the Azure Portal, enter the name of your demo resource group and click **Enter**. In the search results, click on your resource group. You should see the content of your resource group, which should look like this:

     ![Demo resource group](./img/resource-group.png)

### Demos steps

1. Review the content of your demo resource group. It should contain the following resources:

   - `<project name>app`- an app service hosting the Contoso HR web application.
   - `<project name>plan` - an app service plan for the web application.
   - `<project name>server`- a logical server in Azure SQL Database.
   - `<project name>vault` - a key vault in Azure Key Vault, containing the column master key for Always Encrypted.
   - `ContosoHR` - a database.

1. Right-click on the app service for the Contoso HR web application in your resource group and open its **Overview** blade in a new tab. Click on **Configuration** under **Application Settings**. In the **Connection strings** section, click **Advanced edit**. This will display the database connection string configured for the web application. There are two important things to call out in the database connection string:

   - **Column Encryption Setting = Enabled** turns the Always Encrypted on in the client driver, allowing it to transparently encrypt query parameters and decrypt query results.
   - **Attestation Protocol = None** specifies that there is no attestation used. VBS enclaves currently do not support attestation.

   ![Connection string](./img/portal-web-app-connection-string.png)

1. Close the browser tab for the app service. Right-click on the key vault in your resource group and open its **Overview** blade in a new tab.
   1. Click on **Keys** under **Settings**. You should see the entry for the key, named **CMK** - this is your column master key for Always Encrypted.

       ![Connection string](./img/portal-key-vault-key.png)

   2. Click on **Access Policies**. You should see two access policy entries: one for your identity and one for the web app's identity. These policies grant you permissions necessary to perform key management operations and they grant the web app permissions required to decrypt column encryption keys, protecting the data.

1. Close the browser tab for the key vault. Right-click on the logical server in your resource group and open its **Overview** blade in a new tab.
   1. Click on **SQL Databases** and select **ContosoHR** database.
   2. In the left ribbon, click on **Data Encryption** and click in the blade on **Always Encrypted**.
   3. Confirm that the Secure Enclave is enabled and that the enclave type is **Virtualization based security (VBS)**

1. Switch to SSMS.
   1. In Object Explorer, navigate to the **ContosoHR** database. Then go to **Security** > **Always Encrypted Keys**.
   1. Open the **Column Master Keys** and **Column Encryption Keys** folders. You should see the metadata object, named **CMK1**, for the column master key and the metadata object, named **CEK1**, for the column encryption key.
   1. Right click on **CMK1** and select **Properties**. Note that the metadata object references the key in the key vault. Also note **Enclave Computations** is set to **Allowed**, which permits the column encryption key, this columns master key protects, to be used in enclave computations.

      ![Connection string](./img/ssms-cmk.png)

## Demo 2

This short demo highlights the main benefits of Always Encrypted with VBS enclaves. The starting point for the demo is the ContosoHR database with the **SSN** and **Salary** columns already encrypted.

### Prepare for the demo
Perform the below steps before you show the demo.

1. Close all running instances of SQL Server Management Studio (SSMS).
1. Prepare a new instance of SSMS.
   1. Start SSMS.
   1. In the **Connect to Server** dialog:
      1. In the main page of the dialog, enter your database server name. Set **Authentication** to **Azure Active Directory – Universal with MFA**. In the **User Name** field, enter your Azure AD username. You should enter the same username, you used to sign in to Azure, when you set up your demo environment.

         ![Connect to Server](./img/ssms-connect-to-server-main-page.png)

      1. Click the **Options >>** button, select the **Connection Properties** tab and enter the database name (**ContosoHR**).

         ![Connection Properties](./img/ssms-connect-to-server-connection-properties-page.png)

      1. Select the **Always Encrypted** tab. Make sure the **Enable Always Encrypted** checkbox is **not** selected.

         ![Always Encrypted disabled](./img/ssms-connect-to-server-always-encrypted-disabled.png)

      1. Click **Connect**.
      1. When prompted, sign in to Azure.
   1. Configure query windows.
      1. In Object Explorer, find and select the **ContosoHR** database.

        ![Selecting database](./img/ssms-explorer-select-database.png)

      1. With the **ContosoHR** database selected, click Ctrl + O. In the **Open File** dialog, navigate to the **tsql-scripts** folder and select **ListAllEmployees.sql**. Do not execute the query yet.
      1. With the **ContosoHR** database selected, click Ctrl + O. In the **Open File** dialog, navigate to the **tsql-scripts** folder and select **QueryEvents.sql**. Do not execute the query yet.
1. Prepare your web browser.
   1. Open your browser.
   1. Point the browser to the demo application URL.

      ![Web app](./img/web-app.png)

### Demos steps

1. Show the Contoso HR web app in the the browser. This application displays employee records and it allows you to filter and sort employees by salary or by a portion of the social security number (SSN). Move the salary slider and enter a couple of digits in the search box to filter by salary and SSN. Click on the **Ssn** or **Salary** column header to filter by salary or SSN.

   ![Web app filtering](./img/web-app-filtering.png)

1. Switch to SSMS, select the **ListAllEmployees.sql** tab and click **F5** to execute the query, which shows the content of the **Employees** table, the web application uses as a data store. Although you are a DBA of the database, you cannot see the plaintext data in the **SSN** and **Salary** columns, as those two columns are protected with Always Encrypted.

   ![Encrypted results](./img/ssms-encrypted-results.png)

1. Select the **QueryXevents.sql** tab and click **F5** to execute the query. This query retrieves extended events from the **Demo** extended event session, configured in the **ContosoHR** database. Each extended event captures a query the web application has sent to the database.

   ![Extended event results](./img/ssms-xevents-results.png)

1. Click on the link in the second column of the first row of the result set to see the extended event with the latest query from the application. This will open the extended event in the new tab.
   1. Review the query statement. Note that the query contains the **WHERE** clause with rich computations on encrypted columns: pattern matching using the **LIKE** predicate on the **SSN** column and the range comparison on the **Salary** column. The query also sorts records (the **ORDER BY** clause) by **SSN** or **Salary**. **Pro Tip:** to make it easier to view the query statement, you can put line brakes in it.

      ![Extended event](./img/ssms-xevent.png)

   1. Locate the value of query parameters: **@SSNSearchPattern**, **@MinSalary**, **@MaxSalary**. Note that the values of the parameters are encrypted – the client driver inside the web app transparently encrypts parameters corresponding to encrypted columns, before sending the query to the database. Not only does not the DBA have access to sensitive data in the database, but the DBA cannot see the plaintext values of query parameters used to process that data either.

### Key Takeaways

Always Encrypted with secure enclaves allows applications to perform rich queries on sensitive data without revealing the data to potentially malicious insiders, including DBAs in your organization.

## Demo 3

The starting point for this demo is the database with no columns encrypted - the data is initially not protected. The demo shows how to reach the following two objectives:

1. Protect sensitive data in the database by encrypting it in-place.
1. Ensure the Contoso HR web application can continue run rich queries on database columns after encrypting the columns.

During the demo, you will use two instances of SQL Server Management Studio (SSMS):

- DBA's instance - when using it, you will assume the role of a DBA.
- Security Adminsitrator's instance - when using it, you will assume the role of a Security Administrator, who configures Always Encrypted in the database.

### Prepare for the demo
Perform the below steps before you show the demo.

1. Close all running SSMS instances.
1. Prepare DBA's instance of SSMS.
   1. Start SSMS.
   1. In the Connect to Server dialog:
      1. In the main page of the dialog, enter your database server name. Set **Authentication** to **Azure Active Directory – Universal with MFA**. In the **User Name** field, enter your Azure AD username. You should enter the same username, you've used to sign in to Azure, when you set up your demo environment.

         ![Connect to Server](./img/ssms-connect-to-server-main-page.png)

      1. Click the **Options >>** button, select the **Connection Properties** tab and enter the database name (**ContosoHR**).

         ![Connection Properties](./img/ssms-connect-to-server-connection-properties-page.png)

      1. Select the **Always Encrypted** tab. Make sure the **Enable Always Encrypted** checkbox is **not** selected.

         ![Always Encrypted disabled](./img/ssms-connect-to-server-always-encrypted-disabled.png)

      1. Click **Connect**.
      1. When prompted, sign in to Azure.
   1. Configure query windows.
      1. In Object Explorer, find and select the **ContosoHR** database.

         ![Selecting database](./img/ssms-explorer-select-database.png)

      1. With the **ContosoHR** database selected, click Ctrl + O. In the **Open File** dialog, navigate to the **tsql-scripts** folder and select **ListAllEmployees.sql**. Do not execute the query yet.
      1. With the **ContosoHR** database selected, click Ctrl + O. In the **Open File** dialog, navigate to the **tsql-scripts** folder and select **QueryXEvents.sql**. Do not execute the query yet.
1. Prepare Security Administrator's instance of SSMS.
   1. Start SSMS.
   1. In the Connect to Server dialog:
      1. In the main page of the dialog, enter your database server name. Set **Authentication** to **Azure Active Directory – Universal with MFA**. In the **User Name** field, enter your Azure AD username. You should enter the same username, you've used to sign in to Azure, when you set up your demo environment.

         ![Connect to Server](./img/ssms-connect-to-server-main-page.png)

      1. Click the **Options >>** button, select the **Connection Properties** tab and enter the database name (**ContosoHR**).

         ![Connection Properties](./img/ssms-connect-to-server-connection-properties-page.png)

      1. Select the **Always Encrypted** tab. Make sure the **Enable Always Encrypted** and the **Enable secure enclaves** checkbox are selected. Set the Enclave attestation Protocol to **None**.

         ![Always Encrypted disabled](./img/ssms-connect-to-server-always-encrypted-enabled.png)

      1. Click **Connect**.
      1. When prompted, sign in to Azure.
   1. Configure query windows.
      1. In Object Explorer, find and select the **ContosoHR** database.

         ![Selecting database](./img/ssms-explorer-select-database.png)

      1. With the **ContosoHR** database selected, click Ctrl + O. In the **Open File** dialog, navigate to the **tsql-scripts** folder and select **DecryptColumns.sql**. **Click **F5** to execute the query**, which will decrypt the **SSN** and **Salary** columns in the database.
      1. With the **ContosoHR** database selected, click Ctrl + O. In the **Open File** dialog, navigate to the **tsql-scripts** folder and select **EncryptColumns.sql**. Do not execute the query yet.
1. Prepare your web browser.
   1. Open your browser.
   1. Point the browser to the demo application URL.

      ![Web app](./img/web-app.png)

### Demos steps

1. Show the Contoso HR web app in the the browser. This application displays employee records and allows you to filter employees by salary or by a portion of the social security number (SSN). Move the salary slider and enter a couple of digits in the search box to filter by salary and SSN.

   ![Web app filtering](./img/web-app-filtering.png)

1. Switch to DBA's instance of SSMS, select the **ListAllEmployees.sql** tab and click **F5** to execute the query, which shows the content of the **Employees** table, the web application uses as a data store. As a DBA, you can view all sensitive information about employees, including the data stored in the **SSN** and **Salary** columns. A malicious DBA could easily exfiltrate the data by running a simple query like this one.

   ![Encrypted results](./img/ssms-plaintext-results.png)

1. Select the **QueryXevents.sql** tab and click **F5** to execute the query. This query retrieves extended events from the **Demo** extended event session, configured in the **ContosoHR** database. Each extended event captures a query the web application has sent to the database.

   ![Extended event results](./img/ssms-xevents-results.png)

1. Click on the link in the second column of the first row of the result set to see the extended event with the latest query from the application. This will open the extended event in the new tab.
   1. Review the query statement. Note that the query contains the **WHERE** clause with rich computations on encrypted columns: pattern matching using the **LIKE** predicate on the **SSN** column and the range comparison on the **Salary** column. The query also sorts records (the **ORDER BY** clause) by **SSN** or **Salary**. **Pro Tip:** to make it easier to view the query statement, you can put line brakes in it.

      ![Extended event with plaintext parameters](./img/ssms-xevent-plaintext.png)

   1. Locate the value of query parameters: **@SSNSearchPattern**, **@MinSalary**, **@MaxSalary**. Note that the values of the parameters are in plaintext, as the columns, the parameters correspond  to, are not encrypted.

1. Switch to Security Administrator's instance of SSMS, select the **EncryptColumns.sql** tab and click **F5** to execute the query, encrypts the data in the **SSN** and **Salary** columns in place, using the secure enclave.

1. Switch back to DBA's instance of SSMS, select the **ListAllEmployees.sql** tab and click **F5** to execute the query again. Now the query should show the encrypted data in the **SSN** and **Salary** columns. As both columns are encrypted, the DBA cannot see the data in plaintext.

   ![Encrypted results](./img/ssms-encrypted-results.png)

1. In the web browser, move the slider to reset the filter for salary and then re-enter a few digits of an SSN. Confirm the application still can filter employee records by salary and SSN.

1. Switch to DBA's instance of SSMS, select the **QueryXevents.sql** tab and click **F5** to re-run the query.

1. Click on the link in the second column of the first row of the result set to see the extended event with the latest query from the application. This will open the extended event in the new tab.
   1. Review the query statement. Note that the query statement the query sends to the database has not changed - it still contains pattern matching using the **LIKE** predicate on the **SSN** column and the range comparison on the **Salary** column, as well as sorting  (the **ORDER BY** clause) by **SSN** or **Salary**. **Pro Tip:** to make it easier to view the query statement, you can put line brakes in it.

      ![Extended event](./img/ssms-xevent.png)

   1. Locate the value of query parameters: **@SSNSearchPattern**, **@MinSalary**, **@MaxSalary**. Note that the values of the parameters are now encrypted – the client driver inside the web app transparently encrypts parameters corresponding to encrypted columns, before sending the query to the database. Not only does not the DBA have access to sensitive data in the database, but the DBA cannot see the plaintext values of query parameters used to process that data either.

### Key Takeaways

Secure enclaves make it possible to encrypt sensitive data columns in-place, eliminating a need to move the data outside of the database for cryptographic operations.

The unique benefit of Always Encrypted with secure enclaves is that it allows you to protect your sensitive data from high-privilege users, including DBAs in your organization, and, after you encrypt your data to protect it, your applications can continue running rich queries on encrypted columns.
## Cleanup

To permanently remove all demo resources:

1. Run the **cleanup.ps1** PowerShell script in the setup folder.
1. When prompted, enter your demo resource group name and your subscripton id, and sign in to Azure.
1. Confirm you want to delete resource group.
1. Confirm you want to permanently delete the key vault.
