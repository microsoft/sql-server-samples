-- ===========================================
-- Extended Properties on Database template
-- ===========================================
USE <database_name, sysname, AdventureWorks>
GO

-- Add an extended property to a database
EXEC sp_addextendedproperty
	@name=N'<database_ex_prop_name,,Created_By>',
	@value=N'<database_ex_prop_value,,Property value here>'
GO

-- Modify an existing extended property on a database
EXEC sp_updateextendedproperty
	@name=N'MS_Description',
	@value=N'<new_MS_Description_value,,AdventureWorks Sample Database>'
GO

-- List the extended properties for the database object
SELECT name, value
FROM fn_listextendedproperty(default, default, default, default, default, default, default);
GO

-- Drop the new extended property (<database_ex_prop_name,,Created_By>)
EXEC sp_dropextendedproperty @name=N'<database_ex_prop_name,,Created_By>'
GO
