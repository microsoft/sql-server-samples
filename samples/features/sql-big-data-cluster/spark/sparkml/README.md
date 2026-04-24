# MLeap on SQL Server Big Data cluster
This folder shows how we can build a model with [Spark ML](https://spark.apache.org/docs/latest/ml-guide.html), export the model to [MLeap](mleap-docs.combust.ml/), and score the model in SQL Server with its [Java Language Extension](https://docs.microsoft.com/en-us/sql/language-extensions/language-extensions-overview?view=sqlallproducts-allversions)

![Train_Score_Export_with_Spark.jpg](Train_Score_Export_with_Spark.jpg)

## Model training with Spark ML
In this sample code, AdultCensusIncome.csv is used to build a Spark ML pipeline model.  We can [download the dataset from internet](mleap_sql_test/setup.sh#L11) and [put it on HDFS on a SQL BDC cluster](mleap_sql_test/setup.sh#L12) so that it can be accessed by Spark.

The data is first [read into Spark](mleap_sql_test/mleap_pyspark.py#L25) and [split into training and testing datasets](mleap_sql_test/mleap_pyspark.py#L64).  We then [train a pipeline mode with the training data](mleap_sql_test/mleap_pyspark.py#L87) and [export the model to a mleap bundle](mleap_sql_test/mleap_pyspark.py#L204).

An equivalent Jupyter notebook is also included [here](train_score_export_ml_models_with_spark.ipynb) if it is preferred over pure Python code.

## Model scoring with SQL Server
Now that we have the Spark ML pipeline model in a common serialization [MLeap bundle](http://mleap-docs.combust.ml/core-concepts/mleap-bundles.html) format, we can score the model in Java without the presence of Spark.

In order to score the model in SQL Server with its [Java Language Extension](https://docs.microsoft.com/en-us/sql/language-extensions/language-extensions-overview?view=sqlallproducts-allversions), we need first build a Java application that can load the model into Java and score it.  The [mssql-mleap-app folder](mssql-mleap-app/build.sbt) shows how that can be done.

Then in T-SQL we can [call the Java application and score the model with some database table](mleap_sql_test/mleap_sql_tests.py#L101).
