-- =============================================
-- Drop extended property
-- =============================================
EXEC sp_dropextendedproperty N'<property_name, sysname, n1>',
			     N'<level0type, , user>', N'<level0name, sysname, dbo>',
			     N'<level1type, , table>', N'<level1name, sysname, authors>',
			     N'<level2type, , column>', N'<level2name, sysname, au_id>'
GO

