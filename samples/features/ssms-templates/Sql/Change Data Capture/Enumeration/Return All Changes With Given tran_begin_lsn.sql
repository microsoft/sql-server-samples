-- =======================================================
-- Return All Changes With a Given tran_begin_lsn Template
-- =======================================================
USE <Database_Name,sysname,Database_Name>
GO

DECLARE @from_lsn binary(10),
	@to_lsn binary(10),
	@database_transaction_begin_lsn numeric(25,0)

SET @from_lsn =
   sys.fn_cdc_get_min_lsn('<capture_instance,sysname,capture_instance>')
SET @to_lsn   = sys.fn_cdc_get_max_lsn()
SET @database_transaction_begin_lsn = <database_transaction_begin_lsn,numeric(25,0),database_transaction_begin_lsn>

SELECT q.*
FROM cdc.fn_cdc_get_all_changes_<capture_instance,sysname,capture_instance>
  (@from_lsn, @to_lsn, N'all') q
INNER JOIN cdc.lsn_time_mapping m
	ON q.__$start_lsn = m.start_lsn
WHERE dbo.fn_convertnumericlsntobinary(@database_transaction_begin_lsn) = m.tran_begin_lsn
GO
