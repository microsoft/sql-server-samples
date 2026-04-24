Implementing Predictive Analytics in Your Applications
============================================================

Predictive analytics are a powerful way to add intelligence to your application, it enables you to predict outcomes against data that is new to your application. The Microsoft data platform provides numerous ways you can add predictive analytics to your applications

What is predictive analytics?
-------------------------------
Before we get into the implementation, let’s address a fundamental question—**what is predictive analytics?** At their core, predictive tasks are those that predict one value given a set of other values as input. In other words, predictive tasks learn (or are taught) how to make predictions. This learning is captured in a model by an algorithm. Think of the model as the way the learnings are compactly summarized. When you want to make a prediction, you invoke a prediction operation and provide the model as one of the inputs, along with the input values against which you want to form a prediction. Predictive analytics is the act of applying prediction (and your model) to your data to gain new insights.

So, **what are some examples of predictive analytics?** These fall out into two basic categories. You have _prediction that aims to predict the class (or category) of something_. For example, you can have single class classification that tries to predict if an email is spam or not spam—so the class is either “spam” or “not spam”. You can also have multi-class classification, that predicts an outcome from a set of possible outcomes. For example, you can have a multi-class classification that predicts if a consumer is at “high risk”, “moderate risk”, or “low risk” of default on a loan.

You also have _numeric prediction_. Instead of trying to predict a class from a fixed set of options, numeric prediction tries to predict a numeric value from a continuous range of numbers. For example, you might try to predict how long of a delay in minutes a flight will experience or the currency value of a particular stock in the stock market.

Prediction on the Microsoft Data Platform
----------------------------------------------
The Microsoft Data Platform provide numerous ways you can build predictive models that you can then integrate into your application. The following diagram summarizes the options:

![Alternatives to train and use a model](imgs/UseModelForPrediction.png "Model Train and use")

As you can infer from the diagram, the act of incorporating predictive analytics into your applications involves two major phases: model creation and model operationalization. Conceptually, these are very simple to understand.

**Model Creation:** During model creation, you train your predictive model (by showing it sample data along with the outcomes) and test that it works (at least that it predicts results better than random chance would). You save this model so you can use it later when you want to make predictions against new data.

**Model Operationalization:** During model operationalization, you are implementing predictions that use your model in whatever hosting environment (such as a web service) makes sense for integration with your application. In other words, operationalization is how you add predictive analytics to your application.

Options for Model Creation
-----------------------------
Let’s begin by understanding the various ways you can train and test your model. When creating your model, you can train your model locally. This is amounts to authoring and running R or Python scripts on your development workstation. For example, you might use the integrated development environment R GUI (a component in Microsoft R Open) or R Tools for Visual Studio to author your R scripts that train your model, help you test it and visualize the results.

Alternately, the training can be done using resources that are remote to your development workstation. The Microsoft Data Platform offers the following options for this:

* **Azure Machine Learning (Azure ML):** Azure ML enables you to design predictive experiments (referred to as scoring experiments) using its browser based Machine Learning Studio. The visual drag-and-drop experience is like designing a flowchart, where each box of the flowchart is called a “module”. Modules can retrieve data, transform data, process data, create predictive models and evaluate their predictive performance. There are numerous built in modules that let you define and run custom script code written in R or Python as desired.

* **HDInsight:** HDInsight provides numerous ways you can train predictive models using a cluster of servers running in Azure. With R Server on Spark and R Server on Hadoop, you author R scripts whose execution runs across the cluster to train (and test) your model. If you deploy an HDInsight with Spark, you can use Spark ML to program the training and testing models using Scala, Java, Python or R. Generally, the data used to train models in HDInsight comes from a form of highly scalable block storage such as HDFS, Azure Data Lake Store or Azure Storage Blobs.

* **SQL R Services:** SQL in R Services enable you to train and test predictive models in the context of SQL Server 2016. You author T-SQL procedures that contain embedded R scripts, and the SQL Server database engine takes care of the execution. Because it executes in the context of SQL Server, your models can be easily trained against data stored within tables within your database.

Option for Model Operationalization
---------------------------------------
The Microsoft Data Platform also provide multiple ways of adding predictive analytics to an application. As you can see in the diagram, while there are many ways to train a model there tend to be only a few practical ways to use the model from an application.

*   **Invoke Predict within a Script:** When running within a local environment, you can easily use the trained model as input into your predictive script.

*   **Invoke Predictive Web Service:** When running in a remote environment, a common approach is to encapsulate the call to prediction in a web service/Rest API operation that is readily invoked from an application. For Azure ML, this is as easy as a few clicks to deploy a predictive experiment as a web service. For HDInsight, this amounts to exporting your trained model to a file and importing the model into a compatible host such a Microsoft’s DeployR (for models created with R Server on Spark or Hadoop), which wraps a web services layer around a prediction script written in R.

*   **Invoke a Predictive Store Procedure:** When using SQL R Services, you can package the code that invokes prediction using your model within a stored procedure. Therefore, integrating a prediction into your application becomes a matter of executing a stored a procedure in SQL Server—something that most applications can easily accomplish regardless of whether they are written in .NET, node.js, Java...

While each approach has its merits, in the accompanying lab, we’ll examine how to augment a node.js application with predictive analytics using this last approach that invokes a predictive stored procedure running in SQL Server 2016.

**Done with the intro?**
[Start the lab](scripts/Lab.md)