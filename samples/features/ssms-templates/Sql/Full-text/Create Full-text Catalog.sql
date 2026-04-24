-- =============================================
-- Create Full-text catalog template
-- =============================================
IF EXISTS (
 SELECT *
   FROM sys.fulltext_catalogs
  WHERE name = N'<fulltext_catalog_name, sysname, your_full_text_catalog_name>'
)
	DROP FULLTEXT CATALOG <fulltext_catalog_name, sysname, your_full_text_catalog_name>
GO

CREATE FULLTEXT CATALOG <fulltext_catalog_name, sysname, your_full_text_catalog_name>
GO

