-- =============================================
-- Add extended property
-- =============================================
EXEC sp_addextendedproperty N'<property_name, sysname, n1>', <property_value, sql_variant, 8>,
			    N'<level0type, , user>', N'<level0name, sysname, dbo>',
			    N'<level1type, , table>', N'<level1name, sysname, authors>',
			    N'<level2type, , column>', N'<level2name, sysname, au_id>'
GO

