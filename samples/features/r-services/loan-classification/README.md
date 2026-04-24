#  Loan Classification using SQL Server 2016 R Services #

During an Ignite keynote session, we had shown how customers are able to achieve a scale up of 1 million predictions/sec using SQL Server 2016 R Services. This sample contains all the scripts required to emulate a similar setup using Lending Club data with SQL Server 2016 R Services and an Azure Data Science VM.

**Scripts**
* 1 - Create Database.sql - Creates the database, tables, stored procedures and other associated database objects required to get this sample going
* 2 - ImportCSVData.ps1 - Imports the data from the CSV files, performs the transformations and transfers the data to the **LoanStats** table
* 3 - Create Columnstore Index.sql - This script creates the non-clustered columnstore index which will be used during the loan scoring process
* 4 - Create Model.sql - Creates the model which will be used to score the loans
* 5 - Resource Governor Config.sql - Sample resource governor configuration used for creating the external resource pools
* 6 - Score Loans.ps1 - PowerShell script to start parallel processes to score the loans
* 7 - WhatIf.ps1 - PowerShell script to take an input for the increased interest rate and perform the WhatIf scenario scoring
