-- =============================================
-- Create table with IDENTITY column
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'<table_name, sysname, test_table>'
	   AND 	  type = 'U')
    DROP TABLE <table_name, sysname, test_table>
GO

create table <table_name, sysname, test_table> (
<column_1, sysname, c1> <datatype_for_column_1, , int> IDENTITY(<seed, , 100>, <increment, , 1>),
<column_2, sysname, c2> <datatype_for_column_2, , int> NOT NULL)
GO

