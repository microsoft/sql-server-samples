--=============================================================
-- Create CLR Function template
--
-- This example creates an assembly named "utf8string" in the
-- local database. Then, it creates a CLR function named
-- "GetCurrentTimeMs" that references "GetCurrentTimeMs"
-- of classutf8.Utils in assembly utf8string.
--=============================================================
USE AdventureWorks
GO

CREATE ASSEMBLY utf8string
  FROM '\\MachineName\utf8string\bin\Debug\utf8string.dll'
GO

CREATE FUNCTION GetCurrentTimeMs()
RETURNS bigint
AS EXTERNAL NAME utf8string.utf8string.GetCurrentTimeMs
GO
