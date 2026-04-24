This is a sample C# client app used to demo the coding aspects of Always Encrypted with VBS enclaves using the ContosoHR Database. 

The raw SQL files are here: https://github.com/microsoft/sql-server-samples/blob/master/samples/features/security/always-encrypted-with-secure-enclaves/azure-sql-database-vbs/setup/PopulateDatabase.sql 

...and the entire repo is here https://github.com/microsoft/sql-server-samples/tree/master/samples/features/security/always-encrypted-with-secure-enclaves/azure-sql-database-vbs. 

To setup, you need an environment variable named ConnectContosoHR that is the connection string to your Azure SQL DB instance. eg; `Server=tcp:XXXXXXXserver.database.windows.net;Database=ContosoHR;`

To set the environment variable, open a Command Prompt and use the setx command eg;
setx ConnectContosoHR=`Server=tcp:XXXXXXXserver.database.windows.net;Database=ContosoHR;`

Don't put the enclave-specific settings in the connection string, these are added by the code so you can demo with- and without-AE.

When the code runs, there's a flag in the code:
`bool useAlwaysEncrypted = true;`

You can set this to false and run the code, and then true and re-run.

- When useAlwaysEncrypted==false, you will see a hex dump of the ciphertext fields, SSN and Salary. 
- When useAlwaysEncrypted==true, the code will change the connection string to support AE and then display the plaintext for SSN and Salary.
