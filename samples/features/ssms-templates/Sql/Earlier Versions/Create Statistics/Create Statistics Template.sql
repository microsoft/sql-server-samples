-- =============================================
-- Create Statistics Template
-- =============================================
CREATE STATISTICS <statistics_name, sysname, stats_test>
ON <table_name, sysname, t1>
	(<column_list, sysname, c1>)
WITH
SAMPLE <percentage, , 50> PERCENT
GO

