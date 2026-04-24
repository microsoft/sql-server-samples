# Implementing Transitive Closure Clustering in SQL Server using CLR UDF
SQL Database don't have built-in support for transitive closure clustering, so the only workaround is to implement this algorithm in .Net framework and expose it as T-SQL function.
A discussion on the problem, the algorithm and a pure T-SQL based solution can be found here:
- [Transitive Closure Clustering with SQL Server, UDA and JSON](https://medium.com/@mauridb/transitive-closure-clustering-with-sql-server-uda-and-json-dade18953fd2)
- [T-SQL Puzzle Challenge Grouping Connected Items](http://www.itprotoday.com/microsoft-sql-server/t-sql-puzzle-challenge-grouping-connected-items)

This code sample demonstrates how to create CLR User-Defined aggregate that implements clustering.

### Contents

[About this sample](#about-this-sample)<br/>
[Build the CLR/TransitiveClosure aggregate](#build-functions)<br/>
[Add RegEx functions to your SQL database](#add-functions)<br/>
[Test the functions](#test)<br/>
[Disclaimers](#disclaimers)<br/>

<a name=about-this-sample></a>

## About this sample
1. **Applies to:** SQL Server 2016+ Enterprise / Developer / Evaluation Edition
2. **Key features:**
    - CLR, JSON
3. **Programming Language:** .NET C#
4. **Author:** [Davide Mauri](https://github.com/yorek), Jovan Popovic [jovanpop-msft]

<a name=build-functions></a>

## Build the CLR/TransitiveClosure aggregate

1. Download the source code and open the solution using Visual Studio.
2. Change the password in .pfk file and rebuild the solution in **Release** mode.
3. Open and save TransitiveClosure.tt to generate output T-SQL file that will contain script that inserts .dll file with the Transitive closure clustering aggregate.

<a name=add-functions></a>
## Add Clustering aggregate to your SQL database

File TransitiveClosure.sql contains the code that will import aggregate into SQL Database.

If you have not added CLR assemblies in your database, you should use the following script to enable CLR:
```
sp_configure @configname=clr_enabled, @configvalue=1
GO
RECONFIGURE
GO
```

Once you enable CLR, you can use the T-SQL script to add the clustering aggregate. The script depends on the location where you have built the project, and might look like:
```
CREATE ASSEMBLY TransitiveClosure FROM 'D:\GitHub\sql-server-samples\samples\features\sql-clr\TransitiveClosure\bin\Release\TransitiveClosureAggregatorLibrary.dll' WITH PERMISSION_SET = SAFE;
GO

CREATE SCHEMA TC;
GO

CREATE AGGREGATE TC.CLUSTERING(@id1 INT, @id2 INT)
RETURNS NVARCHAR(MAX)
EXTERNAL NAME TransitiveClosure.[TransitiveClosure.Aggregate];
```

This code will import assembly in SQL Database and add an aggregate that provides clustering functionalities.

<a name=test></a>

## Test the function

Once you create the assembly and expose the aggregate, you can use it to cluster some relational data in T-SQL code:

```
declare @edges table(n1 int, n2 int);

insert into @edges
values
    (1,2),(2,3),(3,4),(4,5),(2,21),(2,22),
    (7,8),(8,9),(9,10);

select TC.CLUSTERING(n1,n2)
from @edges;
```
The result will be JSON document that groups the numbers that belong to the same cluster.
```javascript
{
    "0":[1,2,3,4,5,21,22],
    "1":[7,8,9,10]
}
```
You can transform this JSON document into relational formatusing **OPENJSON** function:
```
select cluster = [key], elements = value
from openjson(
    (select TC.CLUSTERING(n1,n2) from @edges)
);
```
The result of this query is:

|cluster|elements|
|---|---|
|0|[1,2,3,4,5,21,22]|
|1|[7,8,9,10]|

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade applications. This is beyond the scope of this sample.

