# Running a Magic 8-ball Python script in SQL Server big data cluster

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

This is a sample [Python](https://www.python.org/) app, which runs a [Magic 8-Ball](https://en.wikipedia.org/wiki/Magic_8-Ball). This sample creates an app that adds requires a question as input and returns an answer to the question. The code for this sample is in [magic8ball.py](magic8ball.py). The inputs and outputs are shown below.

### Inputs
|Parameter|Description|
|-|-|
|`txt`|The input question on which you would like answered|

### Outputs
|Parameter|Description|
|-|-|
|`result`|The answer of the Magic 8-ball|


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
    azdata login -e https://<ip-address-of-controller-svc-external>:30080 -u <user-name>
    ```
3. Deploy the application by running the following command, specifying the folder where your `spec.yaml` and `magic8ball.py` files are located:
    ```bash
    azdata app create --spec ./magic8ball
    ```
4. Check the deployment by running the following command:
    ```bash
    azdata app list -n magic8ball -v [version]
    ```
    Once the app is listed as `Ready` you can continue to the next step.
5. Test the app by running the following command:
    ```bash
    azdata app run -n magic8ball -v [version] --input txt="Will it rain tomorrow?"
    ```
    You should get output like the example below. The answer to your question are returned as `result`.
    ```json
    {
      "changedFiles": [],
      "consoleOutput": "",
      "errorMessage": "",
      "outputFiles": {},
      "outputParameters": {
        "result": "You may rely on it"
      },
      "success": true
    }
    ```

    > **RESTful web service**. Note that any app you create is also accessible using a RESTful web service that is [Swagger](swagger.io) compliant. See step 6 in the [Addpy sample](../addpy/README.md#restapi) for detailed instructions on how to call the web service.

6. You can clean up the sample by running the following commands:
    ```bash
    # delete app
    azdata app delete --name magic8ball --version [version]
    ```

<a name=sample-details></a>

## Sample details

Please refer to [magic8ball.py](magic8ball.py) for the code for this sample.

### Spec file
Here is the spec file for this application. As you can see the sample uses the `Python` runtime and calls the `magic8ball` method in the `magic8ball.py` file, accepting a `str` input called `txt` (the question that you ask the Magic 8-ball) and returning a `str` output named `result`.

```yaml
name: magic8ball
version: v2
runtime: Python
src: ./magic8ball.py
entrypoint: magic8ball
replicas: 1
poolsize: 1
inputs:
  txt: str
output:
  result: str
```

<a name=related-links></a>

## Related Links
For more information, see these articles:

[How to deploy and app on SQL Server 2019 big data cluster](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps)