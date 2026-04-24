-- ===============================================================
-- Create Unique Clustered Index template for Azure SQL Database
-- ===============================================================

CREATE UNIQUE CLUSTERED INDEX <index_name,sysname,AK_vEmployee_EmployeeID>
ON <schema_name,sysname,HumanResources>.<view_name,sysname,vEmployee>
(
	<column_name,sysname,EmployeeID> ASC
)
WITH
(
	DROP_EXISTING = OFF
)
GO

