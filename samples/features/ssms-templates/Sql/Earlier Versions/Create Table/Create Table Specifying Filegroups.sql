-- =============================================
-- Create table specifying filegroups
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'<table_name, sysname, test_table>'
	   AND 	  type = 'U')
    DROP TABLE <table_name, sysname, test_table>
GO

CREATE TABLE <table_name, sysname, test_table> (
<column_1, sysname, c1> <datatype_for_column_1, , int> NOT NULL,
<column_2, sysname, c2> <datatype_for_column_2, text|ntext|image, text> )
ON <file_group_name_1, , [PRIMARY]>
TEXTIMAGE_ON <file_group_name_2, , [PRIMARY]>
GO

