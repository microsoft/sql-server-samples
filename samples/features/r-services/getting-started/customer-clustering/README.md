# Perform customer clustering with SQL Server R Services

In this sample, we are going to get ourselves familiar with clustering.
Clustering can be explained as organizing data into groups where members of a group are similar in some way.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Sample details](#sample-details)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

We will be using the Kmeans algorithm to perform the clustering of customers. This can for example be used to target a specific group of customers for marketing efforts.
Kmeans clustering is an unsupervised learning algorithm that tries to group data based on similarities. Unsupervised learning means that there is no outcome to be predicted, and the algorithm just tries to find patterns in the data.

In this sample, you will learn how to perform Kmeans clustering in R and deploying the solution in SQL Server 2016.

Follow the step by step tutorial [here](https://www.microsoft.com/en-us/sql-server/developer-get-started/rclustering) to walk through this sample.

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
Section 1 in the [tutorial](https://www.microsoft.com/en-us/sql-server/developer-get-started/rclustering) covers the prerequisites.
After that, you can download a DB backup file and restore it using Setup.sql. [Download DB](https://sqlchoice.blob.core.windows.net/sqlchoice/static/tpcxbb_1gb.bak)

**Software prerequisites:**

<!-- Examples -->
1. SQL Server 2016 (or higher) with R Services installed
2. SQL Server Management Studio
3. R IDE Tool like Visual Studio


<a name=sample-details></a>
## Sample Details

### Customer Clustering.R

The R script that performs clustering.

### Customer Clustering.SQL

The SQL code to create stored procedure that performs clustering, and queries to verify and take further actions.


<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->

For additional content, see these articles:

[SQL Server R Services - Upgrade and Installation FAQ](https://msdn.microsoft.com/en-us/library/mt653951.aspx)

[Other SQL Server R Services Tutorials](https://msdn.microsoft.com/en-us/library/mt591993.aspx)