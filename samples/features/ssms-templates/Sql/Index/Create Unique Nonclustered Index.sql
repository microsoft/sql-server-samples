-- ===================================
-- Create Unique Nonclustered Index
-- ===================================
USE <database_name, sysname, AdventureWorks>
GO

CREATE UNIQUE NONCLUSTERED INDEX <index_name,sysname,AK_EmployeeAddress_rowguid>
ON <schema_name,sysname,HumanResources>.<table_name,sysname,EmployeeAddress>
(
	<column_name,sysname,rowguid> ASC
)
WITH
(
	SORT_IN_TEMPDB = OFF,
	DROP_EXISTING = OFF
)
ON <file_group,,[PRIMARY]>
GO

EXEC sys.sp_addextendedproperty
	@name=N'MS_Description',
	@value=N'<description_index,string,Description of index>' ,
	@level0type=N'SCHEMA',
	@level0name=N'<schema_name,sysname,HumanResources>',
	@level1type=N'TABLE',
	@level1name=N'<table_name,sysname,EmployeeAddress>',
	@level2type=N'INDEX',
	@level2name=N'<index_name,sysname,AK_EmployeeAddress_rowguid>'
GO
