Simply open SSMS, open a query execution plan file (.sqlplan) using File -> Open File, or drag a plan file to SSMS window.
Once the file opens, right-click anywhere inside the tab (not necessarily on top of an operator) and select “Compare Showplan” to get the other .sqlplan file to compare.
This works with any .sqlplan files you have, even from older versions of SQL Server.
Also, this is an offline compare, so there’s no need to be connected to a SQL Server instance.

More information on the Plan Comparison Tool can beb found at https://blogs.msdn.microsoft.com/sql_server_team/tag/comparison-tool
