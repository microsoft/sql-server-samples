# Running a basic Python script in SQL Server big data cluster

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

This is a sample [Python](https://www.python.org/) app, which shows how to run a Python script in SQL Server big data cluster. This sample creates an app that adds two whole numbers and returns the result. The code for this sample is in [add.py](add.py). The inputs and outputs are shown below.

### Inputs
|Parameter|Description|
|-|-|
|`x`|The first whole number to add|
|`y`|The second whole number to add|

### Outputs
|Parameter|Description|
|-|-|
|`result`|The result of adding `x` and `y`|


<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

1. SQL Server big data cluster CTP 2.3 or later.
2. `azdata`. Refer to [installing azdata](https://docs.microsoft.com/en-us/sql/big-data-cluster/deploy-install-azdata) document on setting up the `azdata` and connecting to a SQL Server 2019 big data cluster.

<a name=run-this-sample></a>

## Run this sample

1. Clone or download this sample on your computer.
2. Log in to the SQL Server big data cluster using the command below using the IP address of the `controller-svc-external` in your cluster. If you are not familiar with `azdata` you can refer to the [documentation](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps) and then return to this sample.

    ```bash
    azdata login -e https://<ip-address-of-controller-svc-external>:30080 -u <user-name>
    ```
3. Deploy the application by running the following command, specifying the folder where your `spec.yaml` and `add.py` files are located:
    ```bash
    azdata app create --spec ./addpy
    ```
4. Check the deployment by running the following command:
    ```bash
    azdata app list -n addpy -v [version]
    ```
    Once the app is listed as `Ready` you can continue to the next step.
5. Test the app by running the following command:
    ```bash
    azdata app run -n addpy -v [version] --input x=3,y=5
    ```
    You should get output like the example below. The result of adding 3+5 are returned as `result`.
    ```json
    {
      "changedFiles": [],
      "consoleOutput": "",
      "errorMessage": "",
      "outputFiles": {},
      "outputParameters": {
        "result": 8
      },
      "success": true
    }
    ```
6. <a name=restapi></a>Any app you create is also accessible using a RESTful web service that is [Swagger](swagger.io) compliant. See: [Consume an app deployed on SQL Server Big Data Clusters using a RESTful web service](https://docs.microsoft.com/en-us/sql/big-data-cluster/app-consume).
   
7. You can clean up the sample by running the following commands:
    ```bash
    # delete app
    azdata app delete --name addpy --version [version]
    ```

<a name=sample-details></a>

## Sample details

Please refer to [add.py](add.py) for the code for this sample.

### Spec file
Here is the spec file for this application. As you can see the sample uses the `Python` runtime and calls the `add` method in the `add.py` file, accepting two integer inputs named `x` and `y` and returning an integer output named `result`.

```yaml
name: addpy
version: v1
runtime: Python
src: ./add.py
entrypoint: add
replicas: 1
poolsize: 1
inputs:
  x: int
  y: int
output:
  result: int
```

<a name=related-links></a>

## Related Links
For more information, see these articles:

[How to deploy and app on SQL Server 2019 big data cluster](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps)