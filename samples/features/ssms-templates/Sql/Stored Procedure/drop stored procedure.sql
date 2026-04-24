-- =======================================================
-- Drop Stored Procedure
-- =======================================================

-- Drop stored procedure if it already exists
IF EXISTS (
  SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
   WHERE SPECIFIC_SCHEMA = N'<Schema_Name, sysname, Schema_Name>'
     AND SPECIFIC_NAME = N'<Procedure_Name, sysname, Procedure_Name>'
)
   DROP PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
GO