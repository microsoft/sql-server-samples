-- =============================================
-- Configure linked server
-- =============================================
sp_serveroption @server   = N'<server_name, sysname, server1>',
    		@optname  = '<option_name, varchar(35), dist>',
    		@optvalue = N'<option_value, nvarchar(128), OFF>'
GO

