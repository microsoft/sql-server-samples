-- =============================================
-- Create Aggregate Template
-- =============================================
IF EXISTS(
	SELECT *
      FROM sys.objects
	 WHERE name = N'<aggregate_name, sysname, sample_aggregate>'
       AND (type = 'AF')
)
	DROP AGGREGATE <aggregate_name, sysname, sample_aggregate>
GO

CREATE AGGREGATE <aggregate_name, sysname, sample_aggregate>(@<parameter_name, sysname, parameter1> <parameter_type, sysname, nvarchar(4000)>)
	RETURNS <return_type, sysname, nvarchar(4000)>
	EXTERNAL NAME <assembly_name, sysname, sample_assembly>.<clr_type_name, sysname, sample_clr_name>
GO
