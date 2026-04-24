-- =============================================
-- Create index full syntax template
-- =============================================
CREATE UNIQUE CLUSTERED INDEX <index_name, sysname, ind_test>
ON <database_name, sysname, pubs>.<owner, sysname, dbo>.<table_or_view_name, sysname, authors>
	(<column_1, sysname, au_lname> DESC,
	 <column_2, sysname, au_fname>)
WITH
PAD_INDEX,
FILLFACTOR = <fillfactor_value, , 50>,
IGNORE_DUP_KEY,
DROP_EXISTING,
STATISTICS_NORECOMPUTE
ON <name_of_filegroup, , [PRIMARY]>
GO

