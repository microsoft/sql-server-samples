# Running a R script that returns a data frame in SQL Server big data cluster

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

This is a sample [R](https://www.r-project.org/) app, which shows how to run a R script in SQL Server big data cluster. This sample creates an app that simulates the rolling of dice. The code for this sample is in [roll-dice.R](roll-dice.R). The inputs and outputs are shown below.

### Inputs
|Parameter|Description|
|-|-|
|`x`|The number of dice to roll|

### Outputs
|Parameter|Description|
|-|-|
|`result`|Data frame containing the results of the dice rolls: `"Blue": [2], "Green": [6], "Red": [1]`|


<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server big data cluster CTP 2.3 or later.
2. `azdata`. Refer to [installing azdata](https://docs.microsoft.com/en-us/sql/big-data-cluster/deploy-install-azdata?view=sqlallproducts-allversions) document on setting up the `azdata` and connecting to a SQL Server 2019 big data cluster.

<a name=run-this-sample></a>

## Run this sample

1. Clone or download this sample on your computer.
2. Log in to the SQL Server big data cluster using the command below using the IP address of the `controller-svc-external` in your cluster. If you are not familiar with `azdata` you can refer to the [documentation](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps?view=sqlallproducts-allversions) and then return to this sample.

    ```bash
    azdata login -e https://<ip-address-of-controller-svc-external>:30080 -u <user-name> -p <password>
    ```
3. Deploy the application by running the following command, specifying the folder where your `spec.yaml` and `roll-dice.R` files are located:
    ```bash
    azdata app create --spec ./RollDice
    ```
4. Check the deployment by running the following command:
    ```bash
    azdata app list -n roll-dice -v [version]
    ```
    Once the app is listed as `Ready` you can continue to the next step.
5. Test the app by running the following command:
    ```bash
    azdata app run -n roll-dice -v [version] --input x=3
    ```
    You should get output like the example for three dice below. The results of the dice rolled are in the `result` data frame:
    ```json
    {
      "changedFiles": [],
      "consoleOutput": "",
      "errorMessage": "",
      "outputFiles": {},
      "outputParameters": {
        "result": {
          "Blue": [
            2
          ],
          "Green": [
            6
          ],
          "Red": [
            1
          ]
        }
      },
      "success": true
    }
    ```

    > **RESTful web service**. Note that any app you create is also accessible using a RESTful web service that is [Swagger](swagger.io) compliant. See step 6 in the [Addpy sample](../addpy/README.md#restapi) for detailed instructions on how to call the web service.

6. You can clean up the sample by running the following commands:
    ```bash
    # delete app
    azdata app delete --name roll-dice --version [version]
    ```

<a name=sample-details></a>

## Sample details

Please refer to [roll-dice.R](roll-dice.R) for the code for this sample.

### Spec file
Here is the spec file for this application. As you can see the sample uses the `R` runtime and calls the `rollEm` method in the `roll-dice.R` file, accepting an integer input named `x` for the number of dice and providing an data frame named `result` as the output.

```yaml
name: roll-dice
version: v1
runtime: R
src: ./roll-dice.R
entrypoint: rollEm
replicas: 1
poolsize: 1
inputs:
  x: integer
output:
  result: data.frame
```

<a name=related-links></a>

## Related Links
For more information, see these articles:

[How to deploy and app on SQL Server 2019 big data cluster](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps)