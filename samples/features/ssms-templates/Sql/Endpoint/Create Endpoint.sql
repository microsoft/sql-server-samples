-- ===========================
-- Create Endpoint Template
-- ===========================
USE <Database_Name, SYSNAME, Database_Name>
GO

----------------------------------------------------------------------------
-- First create a stored procedure that will be exposed as a web service
----------------------------------------------------------------------------
IF EXISTS (
  SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
   WHERE SPECIFIC_SCHEMA = N'<Schema_Name, sysname, Schema_Name>'
     AND SPECIFIC_NAME = N'<Procedure_Name, sysname, Procedure_Name>'
)
   DROP PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
GO

CREATE PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
	(@msg NVARCHAR(256))
AS
	SELECT @msg AS message
GO


----------------------------------------------------------------------------
-- Then, create the HTTP endpoint to expose hello_world_proc as a webmethod
----------------------------------------------------------------------------
IF EXISTS (
	SELECT name from sys.http_endpoints
	WHERE name = N'<endpoint_name, SYSNAME, endpoint_name>'
)
	DROP ENDPOINT <endpoint_name, SYSNAME, endpoint_name>
GO

CREATE ENDPOINT <endpoint_name, SYSNAME, endpoint_name>
	STATE = STARTED
	AS HTTP (
		path='/sql/hello_world',
		AUTHENTICATION=(INTEGRATED),
		PORTS = (CLEAR)
	)
	FOR SOAP(
		WEBMETHOD 'http://tempuri.org/' . '<Procedure_Name, SYSNAME, Procedure_Name>' (NAME = '<Database_Name, SYSNAME, Database_Name>.<Schema_Name, SYSNAME, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>' ),
		WSDL = DEFAULT,
		BATCHES=ENABLED
	)
GO

