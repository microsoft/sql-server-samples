-- =============================================
-- Drop linked server
-- =============================================
sp_dropserver @server     = N'<server_name, sysname, server1>',
	      @droplogins = <option, char(10), NULL>
GO

-- =============================================
-- List linked server
-- =============================================
sp_linkedservers
GO

