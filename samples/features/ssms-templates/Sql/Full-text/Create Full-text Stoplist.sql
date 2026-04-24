-- =============================================
-- Create Full-text stoplist template
-- =============================================
IF EXISTS (
 SELECT *
   FROM sys.fulltext_stoplists
  WHERE name = N'<fulltext_stoplist_name, sysname, your_full_text_stoplist_name>'
)
	DROP FULLTEXT STOPLIST <fulltext_stoplist_name, sysname, your_full_text_stoplist_name>
GO

CREATE FULLTEXT STOPLIST <fulltext_stoplist_name, sysname, your_full_text_stoplist_name>
GO

