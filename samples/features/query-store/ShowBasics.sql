/*Clear Query Store and procedure cache*/
ALTER DATABASE AdventureWorks2016_EXT SET QUERY_STORE CLEAR;
ALTER DATABASE AdventureWorks2016_EXT SET QUERY_STORE = ON (QUERY_CAPTURE_MODE = ALL);
DBCC FREEPROCCACHE
GO
USE AdventureWorks2016_EXT;
GO

/*Run simple query - what data is collected and where does it go to?*/
SELECT * FROM Part;

SELECT * FROM sys.query_store_query_text;
SELECT * FROM sys.query_store_query;
SELECT * FROM sys.query_store_plan;
SELECT * FROM sys.query_store_runtime_stats;

/*
	Combine all info
	vw_QueryStoreCompileInfo is custom view (created for presentation)

*/
SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part'

/*The same query from the proc*/
DROP PROCEDURE IF EXISTS sp_GetParts
GO

CREATE PROCEDURE sp_GetParts
AS
SELECT * FROM Part;
GO

EXEC sp_GetParts;

/*Again the same query, from sp_executesql*/
EXEC sp_executesql N'SELECT * FROM Part'

SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part'

/*Finally trigger*/
DROP TRIGGER IF EXISTS dbo.OnPartInsert
GO

CREATE TRIGGER dbo.OnPartInsert
   ON  dbo.Part
   AFTER INSERT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT * FROM Part;

END
GO

INSERT INTO Part VALUES (3000020, 'Part_300020');

SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part'

/*What happens with parametrized query?*/
SELECT * FROM Part WHERE PartId = 5;

SELECT * FROM vw_QueryStoreCompileInfo
WHERE query_sql_text = 'SELECT * FROM Part = 5'

/* Check sys.query_store_query_text */

SELECT * FROM sys.query_store_query_text;

/*Try sys.fn_stmt_sql_handle_from_sql_stmt this instead*/
SELECT * FROM sys.fn_stmt_sql_handle_from_sql_stmt
('SELECT * FROM Part WHERE PartId = 5', NULL)

/*Changed searched criteria*/
SELECT V.* FROM vw_QueryStoreCompileInfo V
JOIN sys.fn_stmt_sql_handle_from_sql_stmt
('SELECT * FROM Part WHERE PartId = 5', NULL) F
ON V.statement_sql_handle = F.statement_sql_handle

/*Get runtime info for the queries*/
SELECT * FROM vw_QueryStoreRuntimeInfo
WHERE query_sql_text = 'SELECT * FROM Part'
ORDER BY start_time DESC

SELECT * FROM vw_QueryStoreRuntimeInfo V
JOIN sys.fn_stmt_sql_handle_from_sql_stmt
('SELECT * FROM Part WHERE PartId = 5', NULL) F
ON V.statement_sql_handle = F.statement_sql_handle
ORDER BY start_time DESC


