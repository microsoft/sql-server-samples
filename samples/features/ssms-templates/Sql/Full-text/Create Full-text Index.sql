-- =============================================
-- Basic Create Full-text Index Template
--
-- This template assumes there is already a
-- full-text catalog in your database
-- =============================================
IF EXISTS(
	SELECT *
	  FROM sys.fulltext_indexes
      JOIN sys.tables
        ON sys.tables.object_id = sys.fulltext_indexes.object_id
	 WHERE sys.tables.name = '<table_name, sysname, your_table_name>'
)
  DROP FULLTEXT INDEX ON <table_name, sysname, your_table_name>
GO

CREATE FULLTEXT INDEX ON <table_name, sysname, your_table_name> (<column_name, sysname, your_table_column_name>)
	KEY INDEX <full_text_index_name, sysname, your_full_text_index_name>
	ON <full_text_catalog_name, sysname, your_full_text_catalog_name>
	WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM)
GO
