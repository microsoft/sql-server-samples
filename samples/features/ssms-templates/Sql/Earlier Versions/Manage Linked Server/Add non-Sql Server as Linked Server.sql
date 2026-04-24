-- =============================================
-- Add another non-Sql Server as linked server
-- =============================================
sp_addlinkedserver @server     = N'<server_name, sysname, server1>',
		   @srvproduct = N'<product_name, nvarchar(128), Microsoft.Jet.OLEDB.4.0>',
   		   @provider   = N'<provider_name, nvarchar(128), OLE DB Provider for Jet>',
		   @datasrc    = N'<data_source, nvarchar(4000), C:\MSOffice\Access\Samples\Northwind.mdb>',
		   @location   = <location, nvarchar(4000), NULL>,
		   @provstr    = <provider_string, nvarchar(4000), NULL>,
		   @catalog    = <catalog, sysname, NULL>
GO

-- =============================================
-- List linked server
-- =============================================
sp_linkedservers
GO

