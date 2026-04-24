-- =============================================
-- Drop Aggregate Template
-- =============================================
IF EXISTS(
	SELECT *
      FROM sys.objects
	 WHERE name = N'<aggregate_name, sysname, test_agg>'
       AND (type = 'AF')
)
	DROP AGGREGATE <aggregate_name, sysname, test_agg>
GO
