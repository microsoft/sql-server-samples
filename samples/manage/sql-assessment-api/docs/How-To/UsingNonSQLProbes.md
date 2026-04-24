# Retrieving Data from Operating System

In the SQL Assessment API, most of the probes use T-SQL to get data for assessment. However, there are probes that obtain data from the operating system not presented in SQL Server dynamic management views. In order for these probes to get data, the [xp_cmdshell](https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-cmdshell-transact-sql) stored procedure and PowerShell access should be enabled on the target SQL Server. While these facilities are disabled, some checks may be skipped.

Keep in mind that the [xp_cmdshell](https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-cmdshell-transact-sql) stored procedure should be enabled temporarily as it is not recommended by the best practices; once you complete the assessment, make sure to disable it.

The following steps are required to enable [xp_cmdshell](https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-cmdshell-transact-sql) and PowerShell:

1. Enable the **xp_cmdshell** stored procedure to work with T-SQL queries, as described in [xp_cmdshell configuration option](https://docs.microsoft.com/sql/database-engine/configure-windows/xp-cmdshell-server-configuration-option).

2. Enable SQL Server PowerShell on the target SQL server, as described in [SQL Server PowerShell](https://docs.microsoft.com/sql/powershell/sql-server-powershell).

3. Make sure that the SQL Server user has access to the **xp_cmdshell** stored procedure. For more information, see [xp_cmdshell (Transact-SQL)](https://docs.microsoft.com/sql/relational-databases/system-stored-procedures/xp-cmdshell-transact-sql).

4. [Perform assessment](https://docs.microsoft.com/sql/tools/sql-assessment-api/sql-assessment-api-overview?view=sql-server-ver15#get-started-using-sql-assessment-cmdlets).

5. Disable the **xp_cmdshell** stored procedure by executing the following T-SQL query on the target SQL Server.

    ``` sql
    EXECUTE sp_configure 'xp_cmdshell', 0;
    RECONFIGURE
    ```
