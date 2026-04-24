-- =============================================
-- Full-text start population template
-- =============================================
IF EXISTS(
	SELECT *
	  FROM sys.fulltext_indexes
      JOIN sys.tables
        ON sys.tables.object_id = sys.fulltext_indexes.object_id
	 WHERE sys.tables.name = '<table_name, sysname, your_table_name>'
)
ALTER FULLTEXT INDEX ON <table_name, sysname, your_table_name>
	START FULL POPULATION
GO
