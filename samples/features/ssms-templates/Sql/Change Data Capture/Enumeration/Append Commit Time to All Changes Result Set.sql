-- =====================================================
-- Append Commit Time to All Changes Result Set Template
-- =====================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @from_lsn binary(10), @to_lsn binary(10)

SET @from_lsn =
   sys.fn_cdc_get_min_lsn('<capture_instance,sysname,capture_instance>')
SET @to_lsn   = sys.fn_cdc_get_max_lsn()

SELECT q.*, m.tran_end_time AS COMMIT_TIME
FROM cdc.fn_cdc_get_all_changes_<capture_instance,sysname,capture_instance>
  (@from_lsn, @to_lsn, N'all') q
INNER JOIN cdc.lsn_time_mapping m
	ON q.__$start_lsn = m.start_lsn
GO
