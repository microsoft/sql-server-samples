# Sentiment analysis R app using `MicrosoftML` in SQL Server big data cluster

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>

<a name=about-this-sample></a>

## About this sample

This is a sample [R](https://www.r-project.org/) app, which does sentiment analysis on review text using the `MicrosoftML` package. This sample creates an app in SQL Server big data cluster that accepts a `reviewText` text input and returns the estimate sentiment for it. The scoring uses a pre-trained model, stored in `sentiment.rds`. The code for this sample is in [sentiment.R](sentiment.R). The model file `sentiment.rds` was generated using the [model-training.R](model-training.R) script. You don't need to run the model training again, unless you want to retrain with other data. Also, this sample shows how to pass commands to execute when setting up the container using the `pre-package-install.sh` file which runs `apt install` to install the `MicrosoftML` package.
The inputs and outputs for this sample are shown below.

### Inputs
|Parameter|Description|
|-|-|
|`reviewText`|The text to score for sentiment|

### Outputs
|Parameter|Description|
|-|-|
|`out`|A data frame detailing the sentiment score for the `reviewText`|


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
3. Deploy the application by running the following command, specifying the folder where your `spec.yaml`, `sentiment.rds` and `sentiment.R` files are located:
    ```bash
    azdata app create --spec ./sentiment-analysis
    ```
4. Check the deployment by running the following command:
    ```bash
    azdata app list -n sentiment-r -v [version]
    ```
    Once the app is listed as `Ready` you can continue to the next step.
5. Test the app by running the following command:
    ```bash
    azdata app run -n sentiment-r  -v [version] --input reviewText="Absolutely the best movie experience I have ever had!"
    ```
    You should get output like the example below. The result of the sentiment analysis scoring is returned as a data frame in `out`. A `PredictedLabel` equal to `1` indicates the sentiment is deemed positive, whereas a `PredictedLabel` of `0` indicates a negative sentiment. The `Probability.1` indicates the level of certainty for the `PredictedLabel` to be the true sentiment.
    ```json
    {
      "changedFiles": [],
      "consoleOutput": "Beginning processing data.\nRows Read: 1, Read Time: 8.51154e-05, Transform Time: 1.90735e-06\nBeginning processing data.\nElapsed time: 00:00:00.0364881\nFinished writing 1 rows.\nWriting completed.\n",
      "errorMessage": "",
      "outputFiles": {},
      "outputParameters": {
        "out": {
          "PredictedLabel": [
            "1"
          ],
          "Probability.1": [
            0.6523407697677612
          ],
          "Score.1": [
            0.6293442845344543
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
    azdata app delete --name sentiment-r --version [version]
    ```

<a name=sample-details></a>

## Sample details

Please refer to [sentiment.R](sentiment.R) for the code that does loads the pre-trained model and scores the `reviewText`. If you would like to explore the code that trains the model and saves it, see [model-training.R](model-training.R).

### Spec file
Here is the spec file for this application. As you can see the sample uses the `R` runtime and calls the `handler` method in the `sentiment.R` file, accepting a text input named `reviewText` and returning a data frame named `out`.

```yaml
name: sentiment-r
version: v1
runtime: R
src: ./sentiment.R
entrypoint: handler
replicas: 1
poolsize: 1
inputs:
  reviewText: character
output:
  out: data.frame
```

<a name=related-links></a>

## Related Links
For more information, see these articles:

[How to deploy and app on SQL Server 2019 big data cluster](https://docs.microsoft.com/en-us/sql/big-data-cluster/big-data-cluster-create-apps)