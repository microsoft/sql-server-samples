# Running or scheduling a SQL Server Integration Services package in SQL Server big data cluster

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

This is a sample [SQL Server Integration Services (SSIS)](https://docs.microsoft.com/en-us/sql/integration-services/sql-server-integration-services?view=sql-server-2017) app, which shows how to run a SSIS package as a scheduled service. This sample creates an app that is called each minute that executes an SSIS package. It also shows you how to run the SSIS package on demand. The SSIS package creates a backup of the `DWConfiguration` database on the master SQL instance to disk. Also, the package cleans any backup files for the `DWConfiguration` database that are older than one hour, making sure that maximum 60 backup files will be on disk at any moment.

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server big data cluster CTP 2.3 or later.
2. `azdata`. Refer to [installing azdata](https://docs.microsoft.com/en-us/sql/big-data-cluster/deploy-install-azdata?view=sqlallproducts-allversions) document on setting up the `azdata` and connecting to a SQL Server big data cluster.
3. Optional: to see the SSIS package itself, install Visual Studio 2017 if you don't have it already. After that download and install [SSDT](https://docs.microsoft.com/en-us/sql/ssdt/download-sql-server-data-tools-ssdt?view=sql-server-2017#ssdt-for-vs-2017-standalone-installer). 
4. Optional: install [SSMS](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-2017) if it is not already installed.

<a name=run-this-sample></a>

## Run this sample

1. Clone or download this sample on your computer.
2. Log in to the SQL Server big data cluster using the command below using the IP address of the `controller-svc-external` in your cluster. If you are not familiar with `azdata` you can refer to the [documentation](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps?view=sqlallproducts-allversions) and then return to this sample.

    ```bash
    azdata login -e https://<ip-address-of-controller-svc-external>:30080 -u <user-name>
    ```
3. Replace `[SA_PASSWORD]` in the `spec.yaml` file with the password for SQL user `sa`.
4. Deploy the application by running the following command, specifying the folder where your `spec.yaml` and `back-up-db.dtsx` files are located:
    ```bash
    azdata app create --spec ./SSIS
    ```
5. Check the deployment by running the following command:
    ```bash
    azdata app list --name back-up-db --version [version]
    ```
    Once the app is listed as `Ready` the job should run within a minute.
    You can check if the backup is created by running:
    ```bash
    kubectl -n [your namespace] exec -it master-0 -c mssql-server -- /bin/bash -c "ls /var/opt/mssql/data/*.DWConfigbak"
    ```
    You should see a backup being created for every run of the job, with a maximum of 60 backups since the SSIS package cleans up backups older than one hour.
    You can use any of the `.DWConfigbak` files to restore the database.
6. You can clean up the sample by running the following commands:
    ```bash
    # delete app
    azdata app delete --name back-up-db --version [version]
    # delete backup files
    kubectl -n [your namespace] exec -it mssql-master-pool-0 -c mssql-server -- /bin/bash -c "rm /var/opt/mssql/data/*.DWConfigbak"
    ```

<a name=sample-details></a>

## Sample details

Please open to [Visual Studio solution](back-up-db.sln) to see the SSIS package. 

### Spec file
Here is the spec file for this application. This sample uses the `SSIS` runtime and does not specify any `inputs` or `outputs`. Next to that, the spec file in this example specifies `options` and `schedule`:

|Setting|Description|
|-|-|
|options|Specifies any command line parameters passed to the execution of the SSIS package|
|schedule|Specifies when the job should run. This follows cron expressions. A value of '*/1 * * * *' means the job runs *every minute*. If omitted the package will not run automatically and you can run the package on demand using `azdata run -n back-up-db -v [version]` or making a call to the API.|

```yaml
name: back-up-db
version: v1
runtime: SSIS
entrypoint: ./back-up-db.dtsx
options: /REP V /CONN "MasterSQL"\;"\"Data Source=master-svc;User ID=sa;Initial Catalog=master;Password=[SA_PASSWORD]\""
schedule: "*/1 * * * *"
```

<a name=related-links></a>

## Related Links
For more information, see these articles:

[How to deploy and app on SQL Server 2019 big data cluster](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps)