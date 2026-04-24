-- =============================================
-- Create index basic template
-- =============================================
CREATE INDEX <index_name, sysname, ind_test>
ON <database_name, sysname, pubs>.<owner, sysname, dbo>.<table_or_view_name, sysname, authors>
	(<column_1, sysname, au_lname>,
	 <column_2, sysname, au_fname>)
GO



