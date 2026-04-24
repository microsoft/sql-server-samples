-- remove features not supported in Azure SQL Database Standard tier
CREATE PROCEDURE [Application].[Configuration_PrepareForAzureStandard]
AS

  EXEC [Application].[Configuration_RemoveColumnstoreIndexing]

  EXEC [Application].[Configuration_DisableInMemory]

RETURN 0
