------------------------------------------------------------------------
-- Project:      sp_drop_create_stats_external_table                  --
--                                                                    --
--               The stored procedure is able to generate all the     --
--               T-SQL statements for drop and create statistics      --
--               defined on SQL Server external tables in your        --
--               database!                                            --
--                                                                    --
-- File:         Stored procedure implementation                      --
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/   --
-- Notes:        --                                                   --
------------------------------------------------------------------------


IF OBJECT_ID('dbo.sp_drop_create_stats_external_table', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_drop_create_stats_external_table;
GO

CREATE PROCEDURE dbo.sp_drop_create_stats_external_table
AS BEGIN
  /*
    Author: Sergio Govoni https://www.linkedin.com/in/sgovoni/
    Version: 1.0
    License: MIT License
  */

  DECLARE
    -- Output table
    @DropCreateSQLCmd TABLE
	(
	  ID INTEGER IDENTITY(1, 1) NOT NULL
	  ,SchemaName SYSNAME NOT NULL
    ,TableName SYSNAME NOT NULL
    ,ObjectType SYSNAME NOT NULL
    ,OperationType NCHAR(1) NOT NULL
    ,SQLCmd NVARCHAR(1024) NOT NULL
	);

  -- Generate CREATE STATISTICS statements
  WITH StatCreate AS
  (
    SELECT
      'A' AS RowType
      ,T.[object_id]
      ,T.stats_id
      ,T.StatLevel
      ,T.KeyOrdinal
      ,T.SchemaName
      ,T.TableName
      ,CAST('CREATE ' +
            'STATISTICS [' + TRIM(T.StatsName) +
            '] ON [' + TRIM(T.SchemaName) +
            '].[' + TRIM(T.TableName) +
            '] ( ' AS VARCHAR(MAX)) AS SQLCmd
    FROM
    (
      SELECT
        DISTINCT
        stat.[object_id] 
        ,stat.stats_id
        ,CAST(0 AS INTEGER) AS StatLevel
        ,CAST(0 AS INTEGER) AS KeyOrdinal
        ,stat.name AS StatsName
        ,sch.name AS SchemaName
        ,obj.name AS TableName
      FROM
        sys.stats_columns AS statc
      JOIN
        sys.stats AS stat ON ((stat.stats_id = statc.stats_id)
                             AND (stat.[object_id] = statc.[object_id]))
      JOIN
        sys.objects AS obj ON statc.[object_id] = obj.[object_id]
      JOIN
        sys.external_tables external_tab ON ((external_tab.[object_id] = obj.[object_id])
                                            AND (external_tab.[schema_id] = obj.[schema_id]))
      JOIN
        sys.columns AS col ON ((col.column_id = statc.column_id)
                              AND (col.[object_id] = statc.[object_id]))
      JOIN
        sys.schemas AS sch ON obj.[schema_id] = sch.[schema_id]
    WHERE
      ((stat.auto_created = 1) OR (stat.user_created = 1))
      AND (obj.type = 'U')
    ) AS T

    UNION ALL
 
    SELECT
      'R' AS RowType
      ,statcol.[object_id]
      ,statcol.stats_id
      ,CAST(S.StatLevel + 1 AS INTEGER) AS IdxLevel
      ,CAST(statcol.stats_column_id AS INTEGER) AS KeyOrdinal
      ,S.SchemaName
      ,S.TableName
      ,CAST(S.SQLCmd + CASE(statcol.stats_column_id) WHEN 1 THEN '' ELSE ',' END +
            '[' + TRIM(col.name) +
            '] ' AS VARCHAR(MAX)) AS SQLCmd
    FROM
      StatCreate AS S
    JOIN
      sys.stats_columns AS statcol ON ((statcol.[object_id] = S.[object_id])
                                      AND (statcol.stats_id = S.stats_id))
    JOIN
      sys.columns AS col ON ((col.column_id = statcol.column_id)
                            AND (col.[object_id] = statcol.[object_id]))
    WHERE
      (statcol.stats_column_id = (S.KeyOrdinal + 1))
  ),
  StatCreateGroup AS
  (
    SELECT
      MAX(S.KeyOrdinal) AS MaxKeyOrdinal
      ,S.[object_id]
      ,S.stats_id
    FROM
      StatCreate AS S
    JOIN
      sys.objects AS O ON O.[object_id] = S.[object_id]
    WHERE
      (S.RowType = 'R')
    GROUP BY
      S.[object_id]
      ,S.stats_id
  )
  INSERT INTO @DropCreateSQLCmd
  (
    SchemaName
	  ,TableName
	  ,ObjectType
	  ,OperationType
	  ,SQLCmd
  )
  SELECT
    StatCreate.SchemaName
    ,StatCreate.TableName
    ,'STATS' AS ObjecType
    ,'C' AS OperationType
    ,StatCreate.SQLCmd + ') WITH FULLSCAN;' AS SQLCmd
  FROM
    StatCreateGroup
  JOIN
    StatCreate ON ((StatCreate.[object_id] = StatCreateGroup.[object_id])
                  AND (StatCreate.stats_id = StatCreateGroup.stats_id))
                  AND (StatCreate.KeyOrdinal = StatCreateGroup.MaxKeyOrdinal);

  -- Generate DROP STATISTICS statements
  WITH StatsDrop AS
  (
    SELECT
      T.SchemaName
      ,T.TableName
      ,'STATS' AS ObjectType
      ,'D' AS OperationType
      ,'DROP STATISTICS [' +
	      TRIM(SchemaName) + '].[' +
		    TRIM(TableName) + '].[' +
  	    TRIM(StatisticName) + '];' AS SQLCmd

    FROM (
      SELECT
        sch.[Name] as SchemaName
        ,obj.[Name] as TableName
        ,stat.[Name] as StatisticName
      FROM
        sys.stats AS stat
      INNER JOIN
        sys.objects AS obj ON stat.[object_id] = obj.[object_id]
      INNER JOIN
        sys.external_tables external_tab ON ((external_tab.[object_id] = obj.[object_id])
                                            AND (external_tab.[schema_id] = obj.[schema_id]))
      INNER JOIN
        sys.schemas AS sch ON obj.[schema_id] = sch.[schema_id]
      WHERE
        ((stat.auto_created = 1) OR (stat.user_created = 1))
        AND (obj.type = 'U')
    ) AS T
  )
  INSERT INTO @DropCreateSQLCmd
  (
    SchemaName
	  ,TableName
	  ,ObjectType
	  ,OperationType
	  ,SQLCmd
  )
  SELECT
    SchemaName
	  ,TableName
	  ,ObjectType
	  ,OperationType
	  ,SQLCmd
  FROM
    StatsDrop;

  SELECT
    ID
	  ,SchemaName
	  ,TableName
 	  ,ObjectType
	  ,OperationType
	  ,SQLCmd
  FROM
    @DropCreateSQLCmd;

  RETURN;
END;
GO

/*
EXEC dbo.sp_drop_create_stats_external_table;
GO
*/