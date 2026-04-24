# Implementing Regular Expressions in SQL Server using CLR UDF
SQL Database don't have built-in support for regular expressions, so the only workaround is to use Regular Expressions that exist in .Net framework and expose them as T-SQL functions.
This code sample demonstrates how to create CLR User-Defined functions that expose regular expression functionalities that exist in .Net framework.

### Contents

[About this sample](#about-this-sample)<br/>
[Build the CLR/RegEx functions](#build-functions)<br/>
[Add RegEx functions to your SQL database](#add-functions)<br/>
[Test the functions](#test)<br/>
[Disclaimers](#disclaimers)<br/>

<a name=about-this-sample></a>

## About this sample
1. **Applies to:** SQL Server 2005+ Enterprise / Developer / Evaluation Edition
2. **Key features:**
    - CLR
3. **Programming Language:** .NET C#
4. **Author:** Jovan Popovic [jovanpop-msft]

<a name=build-functions></a>

## Build the CLR/RegEx functions

1. Download the source code and open the solution using Visual Studio.
2. Change the password in .pfk file and rebuild the solution in Retail mode.
3. Open and save SqlClrRegEx.tt to generate output T-SQL file that will contain script that inserts .dll file with the Regex functions, and exposes them as T-SQL/CLR functions.

<a name=add-functions></a>
## Add RegEx functions to your SQL database

File SqlClrRegEx.sql contains the code that will import functions into SQL Database.

If you have not added CLR assemblies in your database, you should use the following script to enable CLR:
```
sp_configure @configname=clr_enabled, @configvalue=1
GO
RECONFIGURE
GO
```

Once you enable CLR, you can use the T-SQL script to add the regex functions. The script depends on the location where you have built the project, and might look like:
```
--Create the assembly
CREATE ASSEMBLY SqlClrRegEx FROM 'D:\GitHub\sql-server-samples\samples\features\sql-clr\RegEx\bin\Release\SqlClrRegEx.dll' WITH PERMISSION_SET = SAFE
GO

CREATE SCHEMA REGEX;
GO

--Create the functions
CREATE FUNCTION REGEX.MATCH (@src NVARCHAR(MAX), @regex NVARCHAR(4000))
RETURNS BIT
AS EXTERNAL NAME SqlClrRegEx.RegEx.CompiledMatch
GO
CREATE FUNCTION REGEX.SUBSTRING (@src NVARCHAR(MAX), @regex NVARCHAR(4000))
RETURNS NVARCHAR(4000)
AS EXTERNAL NAME SqlClrRegEx.RegEx.CompiledSubstring
GO
CREATE FUNCTION REGEX.REPLACE (@src NVARCHAR(MAX), @regex NVARCHAR(MAX), @value NVARCHAR(4000))
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME SqlClrRegEx.RegEx.CompiledReplace
GO
```

This code will import assembly in SQL Database and add three functions that provide RegEx functionalities.

<a name=test></a>

## Test the functions

Once you create the assembly and expose the functions, you can use regular expression functionalities in T-SQL code:

```
IF( REGEX.MATCH('tst123test', '[0-9]+') = 1 )
	SELECT REGEX.SUBSTRING('tst123test', '[0-9]+'), REGEX.REPLACE('tst123test', '[0-9]+', 'XXX')
```

<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade applications. This is beyond the scope of this sample.

