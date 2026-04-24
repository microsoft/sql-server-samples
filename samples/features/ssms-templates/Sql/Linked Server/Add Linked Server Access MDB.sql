-- ========================================
-- Add Linked Server Access MDB template
-- ========================================

EXEC sp_addlinkedserver
	@server = N'<linked_server_name, sysname, NorthwindMDB>',
	@provider = N'Microsoft.Jet.OLEDB.4.0',
	@srvproduct = N'OLE DB Provider for Jet',
	@datasrc = N'<MDB_file_path, nvarchar(4000),C:\AccessDBs\Northwind.mdb>'
GO

-- Set up login mapping using current user's security context
EXEC sp_addlinkedsrvlogin
	@rmtsrvname = N'<linked_server_name, sysname, NorthwindMDB>',
	@useself = N'TRUE',
	@locallogin = NULL,
	@rmtuser = N'<MDB_username, sysname, Admin>',
	@rmtpassword = <MDB_username_password, sysname, NULL>
GO

-- List the tables on the linked server
EXEC sp_tables_ex N'<linked_server_name, sysname, NorthwindMDB>'
GO

-- Select all the rows from the Customer table
SELECT * FROM <linked_server_name, sysname, NorthwindMDB>...Customers
