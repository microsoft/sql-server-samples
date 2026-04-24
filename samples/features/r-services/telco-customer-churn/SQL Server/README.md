**Instructions**


- Restore the database provided (telcoedw2.bak). The database can be downloaded from [here](https://sqlchoice.blob.core.windows.net/sqlchoice/samples/telco-customer-churn/teloedw2.bak)
- Run the code in TelcoChurn-Main.sql



----------
**Description**

- TelcoChurn-Main.sql - Use this T-SQL script to try out the telco customer churn example.
- TelcoChurn-Operationalize.sql - T-SQL scripts to create the stored procedures used in this example.

The database consists of the following tables

- **cdr\_rx\_models** - Contains the serialized R models that are used for predicting customer churn
- **edw\_cdr**- Base Call Detail Records (CDR)
- **edw\_cdr\_train**- Training data
- **edw\_cdr\_test** - Test data
- **edw\_cdr\_test\_pred** - Predicted results


----------
