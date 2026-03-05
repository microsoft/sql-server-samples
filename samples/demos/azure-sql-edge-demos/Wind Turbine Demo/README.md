# Azure SQL Edge Demo

## Overview

The Azure SQL Edge demo is based on a Contoso Renewable Energy, a wind turbine farm that leverages Azure SQL Edge for data processing onboard the generator. 

The demo will walk you through resolving an alert being raised due to wind turbulence being detected at the device. You will train a model and deploy it to SQL DB Edge that will correct the detected wind wake and ultimately optimize power output. 

We will also look at some of the security features available with Azure SQL Edge. 

## Wind Turbine Data Explanation for the Wake Detection model

The data stored in the database table represents the following:


* **RecordId:** _Unique identifier for the entry._
* **TurbineId:** _Unique identifier for the turbine in scope._
* **GearboxOilLevel:** _Oil level recorded for the turbine gear box at the time of the reading._
* **GearboxOilTemp:** _Oil temperature recorded for the turbine gear box at the time of the reading._
* **GeneratorActivePower:** _Active Power recorded by the turbine generator._
* **GeneratorSpeed:** _Speed recorded by the turbine generator._
* **GeneratorTemp:** _Temperature recorded by the turbine generator._
* **GeneratorTorque:** _Torque recorded by the turbine generator._
* **GridFrequency:** _Frequency recorded in the grid for the specific wind turbine._
* **GridVoltage:** _Voltage recorded in the grid for the specific wind turbine._
* **HydraulicOilPressure:** _Current pressure of the hydraulic oil for the wind turbine._
* **NacelleAngle:** _Angle of the nacelle at the time of the reading (the housing that contains all the generating components)._
* **PitchAngle:** _Pitch angle of the blades against the oncoming air stream to obtain the optimal amount of energy._
* **Vibration:** _Vibration of the wind turbine at the time of the reading._
* **WindSpeedAverage:** _Average wind speed calculated from the last X records._
* **Precipitation:** _Flag to represent if rain was present at the time of the reading._
* **WindTempAverage:** _Average wind temperature calculated from the last X records._
* **OverallWindDirection:** _Overall wind direction recorded at the time of the reading._
* **TurbineWindDirection:** _Turbine wind direction recorded at the time of the reading._
* **TurbineSpeedAverage:** _Average turbine speed calculated from the last X records._
* **WindSpeedStdDev:** _Standard Deviation of the last X WindSpeedAverage records._
* **TurbineSpeedStdDev:**  _Standard Deviation of the last X TurbineSpeedAverage records._

The above dataset definition contains trends that will enable us to detect the existence of wake in a wind turbine. There are two main conditions that influence the presence of wind wake:

1.	Overall wind farm and turbine wind direction are both between 40° - 45° degrees.
1.	TurbineSpeedStdDev and WindSpeedStdDev have been too far apart for greater than a minute.

The wind turbine will experience wake when the turbine wind direction is between 40° - 45° degrees and the values of TurbineSpeedStdDev and WindSpeedStdDev are not similar. For example: 
* Wake Present:
    * TurbineWindDirection = 43.5°
    * TurbineSpeedStdDev = 8.231
    * WindSpeedStdDev = 0.23
* Wake Not Present:
    * TurbineWindDirection = 23.5°
    * TurbineSpeedStdDev = 0.921
    * WindSpeedStdDev = 0.213



## Azure Resource Deployment

An Azure Resource Manager (ARM) template will be used to deploy all the required resources in the solution.  Click on the link below to start the deployment.

[![homepage](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fzarmada.blob.core.windows.net%2Farm-deployments-public%2Farm-template-dbedge.json "Deploy template")

TODO ^^ Need to update the ARM location

### Deployment of resources

Follow the steps to deploy the required Azure resources:

**BASICS**  

   - **Subscription**: Select the Subscription.
   - **Resource group**:  Click on 'Create new' and provide a unique name for the Resource Group
   - **Location**: Select the Region where to deploy the resources. Keep in mind that all resources will be deployed to this region so make sure it supports all of the required services. The template has been confirmed to work in West US 2.

1. Read and accept the `TERMS AND CONDITIONS` by checking the box.
1. Click the `Purchase` button and wait for the deployment to finish.

## Post Deployment Configuration

Some resources require some extra configuration.

#### Upload SQL DACPAC 

The Edge Module will require access the DACPAC package in order to setup the database.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **Storage account** resource from the list.
1. Click the **Containers** option in the left menu under **Blob service**.
1. Click the **dacpac** container.
1. Click the **Upload** button.
1. Click the **Select a file** input and select the file under the project folder: `sql/turbine-sensor-db-dacpac.zip`.
1. Click the **Upload** button.
1. Once the file is uploaded, click on it. 
1. Click **Generate SAS** tab.
1. Update the **Expiry** year to 2050.
1. Click **Generate SAS token and URL**
1. Copy the value in **Blob SAS URL** and save it for later in the setup.


##### SQL Security Setup Information

As security settings were deployed as part of the DACPAC package, below is a **review** of the security setup within the database.

1. Create users without a login for simpler testing:
    ```sql
    /* Create users using the logins created */
    CREATE USER OperatorUser WITHOUT LOGIN;
    CREATE USER DataScientistUser WITHOUT LOGIN;
    CREATE USER SecurityUser WITHOUT LOGIN;
    CREATE USER TurbineUser WITHOUT LOGIN;
    ```

1. Assigned permissions for each user:
    ```sql
    /* Grant permissions to users */
    GRANT SELECT ON RealtimeSensorRecord TO OperatorUser;
    GRANT SELECT ON RealtimeSensorRecord TO DataScientistUser;
    GRANT SELECT ON RealtimeSensorRecord TO SecurityUser;
    GRANT SELECT, INSERT ON RealtimeSensorRecord TO TurbineUser;
    ```
    > **Note**: All users can SELECT, however the TurbineUser can also INSERT to the table.

1. For privacy reasons, mask the last 4 digits of the SensorId for the Data Scientist user:
    ```sql
    /*Mask the last four digits of the serial number (Sensor ID) for the Data Scientist User*/
    ALTER TABLE RealtimeSensorRecord
    ALTER COLUMN SensorId varchar(50) MASKED WITH (FUNCTION = 'partial(34,"XXXX",0)');
    DENY UNMASK TO DataScientistUser;
    GO
    ```

1. Add a policy using a filter predicate and a function to manage access to data events:
    *  We updated the SensorType column as it is required in our function then created a new schema to store it.

        ```sql
        /**
        * Operator: Can see all events
        * Data Scientist: Can see everything BUT Hatch Sensor events
        * Security: Can ONLY see Hatch Sensor events
        */
        ALTER TABLE RealtimeSensorRecord
        ALTER COLUMN SensorType sysname
        GO

        CREATE SCHEMA Security;
        GO
        ```
    *  Add the function that will ensure each query is authorized based on Sensor Type/User.       
  

        ```sql
        /**
        * Operator: Can see all events
        * Data Scientist: Can see everything BUT Hatch Sensor events
        * Security: Can ONLY see Hatch Sensor events
        */
        CREATE FUNCTION Security.fn_securitypredicate(@SensorType AS sysname)
        RETURNS TABLE
        WITH SCHEMABINDING
        AS
        RETURN SELECT 1 AS fn_securitypredicate_result
            WHERE
                USER_NAME() = 'OperatorUser' OR USER_NAME() = 'dbo' OR
                (USER_NAME() = 'DataScientistUser' AND @SensorType <> 'HatchSensor') OR
                (USER_NAME() = 'SecurityUser' AND @SensorType = 'HatchSensor');
        ```
    * Add a filter to to use the function.


        ```sql
        CREATE SECURITY POLICY SensorsDataFilter
        ADD FILTER PREDICATE Security.fn_securitypredicate(SensorType)
        ON dbo.RealtimeSensorRecord
        WITH (STATE = ON);
        ```

    

#### Notebook Setup

In this section, we will setup our notebook with the required files for the generation of the wind adapt model.

##### Upload training data file:

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **Storage account** resource.
1. Click the **Containers** option in the left menu under **Blob service**.
1. Click the **azureml-blobstore-GUID** container.
1. Click the **Upload** button in the top.
1. Click the **Select a file** input and select the `ml\data\TrainingDataset.parquet` from your repo.
1. Click the **Upload** button and wait for the upload to finish.

##### Notebook files upload
1. Select **Azure Active Directory** option from the main navigation in the Azure Portal:

    ![Azure Active Directory Option](./images/azure-active-directory-option.png)
1. Copy the **Tenant Id** value from the overview as you will need this value later.
1. Go back to the **Resource Group** you created earlier.
1. Select the **Machine Learning** resource.
1. Take note of the following values to be used later in the deployment
    * Resource Group
    * Workspace Name
    * Subscription ID
    ![Machine Learning Resource](./images/machine-learning-resource.png)
1. Click the **Launch now** button to open the Machine Learning workspace.
1. Click the **Notebooks** option in the left menu under **Author**.
1. Click the **Create new folder** button at the top of the navigation panel.
1. Enter the name `scripts` for as the folder name and click the **Create** button.
1. Click the **Upload files** button at the top of the navigation panel.
1. Select the 2 files inside the `ml\scripts` folder:
    * ml\scripts\train.py
    * ml\scripts\utils.py
1. Select the newly created `scripts` folder from the target directory list.
1. Click the **Upload** button and wait for the upload to finish.
1. Click the **Upload files** button again.
1. Select the following 2 files inside the `ml` folder:
    * ml\utils.py
    * ml\wind-turbine-scikit.ipynb
    > **Note**: The `utils.py` is a different file from the previous step.

1. Select your username folder from the target directory list.
1. Click the **Upload** button.

##### Notebook configuration

We need configure values within the notebook before being able to execute it:

1. Click the `wind-turbine-scikit.ipynb` in the **My files** navigation:
1. Click the **New Compute** button.
1. Enter the name `compute-{your-initials}`.
1. Select **CPU (Central Processing Unit)** from the **Virtual machine type** dropdown.
1. Select the virtual machine size **Standard_D12_v2**.
1. Click the **Create** button and wait for the compute to be created.
    > **Note**: This process can take several minutes; wait until status of **compute** is `Running`.
1. Click the **Edit** dropdown and select the **Edit in Jupyter** option.
    > **Note**: If required, login with your Azure credentials.    
1. Replace the values within the **Setup Azure ML** cell with the values you obtained in the **Notebook files upload** section:
    ```
    interactive_auth = InteractiveLoginAuthentication(tenant_id="<tenant_id>")
    # Get instance of the Workspace and write it to config file
    ws = Workspace(
        subscription_id = '<subscription_id>', 
        resource_group = '<resource_group>', 
        workspace_name = '<workspace_name>',
        auth = interactive_auth)
    ```
1. Click **File** > **Save and Checkpoint** from the menu.
1. Select the **Install requirements** cell and click **Run** from the menu, wait for the script to execute before continuing.
1. Select the **Setup Azure ML** cell and click **Run** from the menu.
    > **IMPORTANT**: Observe the output to **authenticate** via the URL provided (https://microsoft.com/devicelogin).  

1. From here, **Run** the remaining cells sequentially until you have executed the notebook. 
    > **IMPORTANT**: Remember to wait for each cell to execute before continuing.
1. Go back to the azure resource group and click the **Storage Account** resource.
1. Click the **Containers** option in the left menu.
1. Click the container in the list with a name like: `azureml-blobstore-{guid}`.
1. A new file with the name `windturbinewake.model.onnx` will be in the container.
1. Click the `windturbinewake.model.onnx` file 
1. Click the **Generate SAS** tab option.
1. Change the **Expiry** Year to 2050.
1. Click the **Generate SAS token and URL** button and wait for the SAS to be generated.
1. Copy the **Blob SAS URL** value for later in the demo usage section.

    > **IMPORTANT**: As this process does take some time, once you have saved your model to blob storage, you will not be required to execute this every time you run through the demo. Showing the notebook flow may be adequate for demo purposes. You will just need the blob SAS for the **SQL DB Edge Demo Usage** section later in the document. 


#### Device Setup

In this section, we will set up an Edge device within our IoT Hub instance. 

##### Create a new Edge device

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **IoT Hub** resource.
1. Click on **IoT Edge** from the left navigation.
1. Click **+ Add an IoT Edge Device**.
1. Enter a **Device ID** and leave all other fields as default.
1. Click **Save**.
1. Once the device has been created, select the device and copy the **Primary Connection String** for later in this setup.

##### Setup Edge device as a VM

1. Click on the link below to start the deploy to Azure:

    [![homepage](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure%2Fiotedge-vm-deploy%2Fmaster%2FedgeDeploy.json "Deploy device")

1. On the newly launched window, fill in the available form fields:

    * **Subscription**: Your subscription.
    * **Resource group**: Select the resource group you created earlier.
    * **DNS Label Prefix**: Your initials and birth year.
    * **Admin Username**: Enter `microsoft` as default.
    * **Device Connection String**: The device connection string that you got from previous section.
    * **VM Size**: The size of the virtual machine to be deployed.
    * **Ubuntu OS Version**: The version of the Ubuntu OS to be installed on the base virtual machine.
    * **Location**: The geographic region to deploy the virtual machine into, this value defaults to the location of the selected Resource Group.
    * **Authentication Type**: Choose the **password** option.
    * **Admin Password or Key**: Enter `M1cr0s0ft2020`.

1. Accept the **Terms and Conditions**.
1. Select **Purchase** to begin the deployment.

##### SSH into the VM - Optional
1. Once the deployment is complete, go back to the **Resource Group** you created earlier. 
1. Select the **Virtual Machine** resource.
    > **Note**: Take note of the machine name, this should be in the format vm-0000000000000. Also, take note of the associated DNS Name, which should be in the format `<dnsLabelPrefix>.<location>.cloudapp.azure.com`.
    The DNS Name can be obtained from the Overview section of the newly deployed virtual machine within the Azure portal.
    ![VM DNS Name](./images/iotedge-vm-dns-name.png)


1. If you want to SSH into this VM after setup, use the associated DNS Name with the command: `ssh <adminUsername>@<DNS_Name>`. You can use the password you created in the previous step.
    > **IMPORTANT**: There is an optional section at the end of this document showing some example commands. 


##### Setup Visual Studio Code Development Environment

1. Install [Visual Studio Code](https://code.visualstudio.com/Download) (VS Code).
1. Install [Docker Community Edition (CE)](https://docs.docker.com/install/#supported-platforms). Don't sign in to Docker Desktop after Docker CE is installed.
1. Install the following extensions for VS Code:
    * [Azure Machine Learning](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai) ([Azure Account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account) will be automatically installed)
    * [Azure IoT Hub Toolkit](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-toolkit)
    * [Azure IoT Edge](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-edge)
    * [Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
1. Restart VS Code.
1. Select **[View > Command Palette…]** to open the command palette box, then enter **[Python: Select Interpreter]** command in the command palette box to select your Python interpreter.
1. Enter **[Azure: Sign In]** command in the command palette box to sign in Azure account and select your subscription.

##### Build and deploy container image to device

1. Launch Visual Studio Code, and select File > Open Workspace... command to open the `edge\sensor-solution.code-workspace`.
1. Update the .env file with the values for your container registry.
    - In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
    - Select the **Container Registry** resource.
    - Select **Access Keys** from the left navigation.
    - Update the following in `edge/SensorSolution/.env` with the following values from  **Access Keys** within the Container Registry:

        CONTAINER_REGISTRY_NAME=`<Login Server>` (Ensure this is the login server and NOT the Registry Name)

        CONTAINER_REGISTRY_USER_NAME=`<Username>`

        CONTAINER_REGISTRY_PASSWORD=`<Password>`

        SQL_PACKAGE=`<SQL Package Blob URL>` (the one you obtained earlier in the setup)

    - Save the file.
1. Sign in to your Azure Container Registry by entering the following command in the Visual Studio Code integrated terminal (replace <REGISTRY_USER_NAME>, <REGISTRY_PASSWORD>, and <REGISTRY_NAME> with your container registry values set in the .env file IN THE PREVIOUS STEP).

    `docker login -u <CONTAINER_REGISTRY_USER_NAME> -p <CONTAINER_REGISTRY_PASSWORD> <CONTAINER_REGISTRY_NAME>`

    > **IMPORTANT**: Ensure you have `amd64` selected as the architecture in the bottom navigation bar of VS Code.

1. Right-click on `edge/SensorSolution/deployment.debug.template.json` and select the **Build and Push IoT Edge Solution** command to generate a new `deployment.debug.amd64.json` file in the config folder, build a module image, and push the image to the specified ACR repository.
    > **IMPORTANT:** If you have amended code in your module, you will need to increment the version number in `module.json` so the new version will get deployed to the device in the next steps.

    > **Note**: Some red warnings "/usr/bin/find: '/proc/XXX': No such file or directory" and "debconf: delaying package configuration, since apt-utils is not installed" displayed during the building process can be ignored.

1. Ensure you have the correct Iot Hub selected in VS Code.
    - In the Azure IoT Hub extension, click **Select IoT Hub** from the hamburger menu. (Alternatively, select `Azure IoT Hub: Select IoT Hub` from the  **Command Palette**)
    - Select your **Subscription**.
    - Select the **IoT Hub** you created earlier in the setup.
1. Right-click `config\deployment.debug.amd64.json` and select **Create Deployment for a Single Device**.
1. Select the device you created earlier.
1. Wait for deployment to be completed.

#### Web App Settings

Follow the next steps to setup the required module twin connection string property.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **IoT Hub** resource.
1. Click the **IoT Edge** option in the left menu under **Automatic Device Management**.
1. Click the **device** you created earlier.
1. Click the **SensorModule** from the modules list.
1. Copy the **Connection string (primary key)** value and save for the next step.
1. Go back to your **Resource Group**.
1. Select the **App Service** resource.
1. Click the **Configuration** option in the left menu.
1. Under the **Application settings** find the `IoTHub:ModuleConnectionString` and click it.
1. Paste the module connection string that you got before to the `value` input field.
1. Click the **OK** button.
1. Click the **Save** button on the top to apply the change.

## SQL DB Edge Demo Usage

Open the Web App.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **App Service** resource.
1. Click **Browse** to go the application on a desktop machine.

Investigate Turbine Issue
1. Click **view** on the alert. A query is ran against the SQL DB Edge instance.
1. Notice the Operator can't see the Security Alert due to as the permissions we set earlier.
1. You can notice a drop in the **Power Generated** chart.
1. Click the **Environmental** button. 
1. You can notice the **Wind Speed and Direction** at the turbine is a lot more turbulent than the rest of the Wind Farm. This could indicate wind wake.

Now we need to run our notebook in order to generate the Onnx model that we will use to resolve the alert.

>**Important**: As mentioned earlier in the document, you can choose to run through executing the notebook cells in the `Notebook Setup` section again to obtain the model. Or you can use your Blob URL you created during the initial setup.

Now we have our wind adapt model, lets update the module to correct the turbine.

1. Go back to the azure resource group and click the **IoT Hub** resource.
1. Click the **Iot Edge** option in the left menu.
1. Click the created device from previous steps.
1. Click the **SensorModule** from the modules list.
1. Click the **Module Identity Twin** option in the top menu.
1. Find the `properties` section in the json.
1. Find the `desired` section in the json.
1. Find the `OnnxModelUrl` property and update the value with the model Blob URL from the previous section.
1. Click the **Save** button.
1. Go back to the **Web App**.
1. You will notice a notification indicating the alert has been resolved.
1. Click on the **Resfresh** button.
1. Notice the turbine **Wind Speed and Direction** has stabilized.
1. If you go back to the dashboard view. You will notice Unit 34 no longer has an alert. 


#### Restart the demo

This steps allows you to restart the demo.

1. Go back to the azure resource group and click the **IoT Hub** resource.
1. Click the **Iot Edge** option in the left menu.
1. Click the created device from previous steps.
1. Click the **SensorModule** from the modules list.
1. Click the **Module Identity Twin** option in the top menu.
1. Find the `properties` section in the json.
1. Find the `desired` section in the json.
1. Find the `OnnxModelUrl` property set the value as empty.
> **Note**: Since the `Alert` property value was already in `start` we don't need to updated it but the module will set the reported property with this value.

1. Click the **Save** button.
1. Go back to the **Web App** and refresh.
1. After a short time the alert will appear again.

# Optional Steps

This section describe steps that allow us to see extra features of the resources as a reference only.

## Device VM access

Here we will see how to run commands into to the device virtual machine from the terminal using SSH connection.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
2. Select the **Virtual machine** resource.
3. Copy the **DNS name** to use it for the connection.
4. In a terminal run the following command replacing the **DNS name**:` ssh microsoft@<DNS_Name>`
    > **Note**: The above command is assuming that you use the default Admin username when deploying the VM.

5. Enter the password to connect.
    > **Note**: Default password is: `M1cr0s0ft2020`

6. Run the following command to see the list of modules running: `sudo iotedge list`
    > **Note**: You can should be able to see the `AzureSQLDatabaseEdge` and `SensorModule` we deployed earlier. 

7. Run the following command to see the logs of the **Sensor Module**: `sudo iotedge logs SensorModule`
    *   Following we will connect with the edge sql server to run a simple query by doing:
        * Get the list of containers running with docker: `sudo docker container list`.
        * Get the container ID of the `AzureSQLDatabaseEdge` docker image running.
        * Connect to the container using the id that you got and the command: `sudo docker exec -it CONTAINERID /bin/sh`.
        * Connect to the container using: `/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'Microsoft2020$'`.
        * Connect to the database using: `USE [turbine-sensor-db]` and then `go`.
        * Query the number of records in the table using: `select count(*) from RealtimeSensorRecord` and `go`.

# Troubleshooting
### Error when deploying ARM Template
We've seen issues with different subscription types: MSDN, AIRS, etc... not being able to deploy certain resources to certain regions.  We've found that deploying to West US 2 works consistently.  If you have a deployment error, try deploying to West US 2.  The resources inherit their deployment region from the Resource Group location.
