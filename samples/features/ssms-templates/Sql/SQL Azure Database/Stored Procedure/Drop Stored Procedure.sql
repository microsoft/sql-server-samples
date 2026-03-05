-- ==========================================================================================
-- Drop Stored Procedure Template for Azure SQL Database and Azure Synapse Analytics Database
-- ==========================================================================================

-- Drop stored procedure if it already exists
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = N'<Schema_Name, sysname, Schema_Name>'
     AND SPECIFIC_NAME = N'<Procedure_Name, sysname, Procedure_Name>' 
)
   DROP PROCEDURE <Schema_Name, sysname, Schema_Name>.<Procedure_Name, sysname, Procedure_Name>
GO
