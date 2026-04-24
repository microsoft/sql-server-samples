--==========================================================================
-- Alter Table Enable Change Tracking template
--
-- This template enables the Change Tracking on Table with options
--==========================================================================
USE MASTER
GO

ALTER TABLE <schema_name, sysname, dbo>.<table_name, sysname, table_name>
	ENABLE CHANGE_TRACKING	
	WITH
	(
		TRACK_COLUMNS_UPDATED = <track_columns_updated,bit,<track_columns_updated>
	)
GO
