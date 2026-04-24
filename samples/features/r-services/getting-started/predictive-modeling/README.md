# Build a predictive model with SQL Server R Services

This sample shows how to create a predictive model in R and operationalize it with SQL Server 2016.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

Predictive modeling is a powerful way to add intelligence to your application. It enables applications to predict outcomes against new data.
The act of incorporating predictive analytics into your applications involves two major phases:
model training and model operationalization.

In this sample, you will learn how to create a predictive model in R and operationalize it with SQL Server 2016.

Follow the step by step tutorial [here](http://aka.ms/sqldev/R) to walk through this sample.

<!-- Delete the ones that don't apply -->
- **Applies to:** SQL Server 2016 (or higher)
- **Key features:**
- **Workload:** SQL Server R Services
- **Programming Language:** T-SQL, R
- **Authors:** Nellie Gustafsson
- **Update history:** Getting started tutorial for R Services

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.
Section 1 in the [tutorial](http://aka.ms/sqldev/R) covers the prerequisites.
After that, you can download a DB backup file and restore it using Setup.sql. [Download DB](https://deve2e.azureedge.net/sqlchoice/static/TutorialDB.bak)

**Software prerequisites:**

<!-- Examples -->
1. SQL Server 2016 (or higher) with R Services installed
2. SQL Server Management Studio
3. R IDE Tool like Visual Studio


<a name=sample-details></a>
## Sample Details

### PredictiveModel.R

The R script that generates a predictive model and uses it to predict rental counts

### PredictiveModel.SQL

Takes the R code in PredictiveModel.R and uses it inside SQL Server. Creating stored procedures for training and prediction.



<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For additional content, see these articles:

[SQL Server R Services - Upgrade and Installation FAQ](https://msdn.microsoft.com/en-us/library/mt653951.aspx)

[Other SQL Server R Services Tutorials](https://msdn.microsoft.com/en-us/library/mt591993.aspx)