------------------------------------------------------------------------
-- Project:      dbo.sp_identity_rebirth                              --
--                                                                    --
--               Regenerate IDENTITY column values in SQL Server and  --
--               Azure SQL tables, ensuring referential integrity and --
--               preserving related objects like constraints,         --
--               indexes, and triggers.                               --
--                                                                    --
--               This process prevents data overflow errors and       --
--               maintains data consistency without renaming or       --
--               losing linked objects.                               --
--                                                                    --
-- File:         Stored procedure implementation                      --
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/   --
-- Notes:        --                                                   --
------------------------------------------------------------------------

USE [tempdb];
GO

IF OBJECT_ID('dbo.sp_identity_rebirth', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_identity_rebirth;
GO

CREATE PROCEDURE dbo.sp_identity_rebirth
  @SchemaName SYSNAME 
  ,@TableName SYSNAME 
  ,@IdentityColumn SYSNAME 
AS
BEGIN
  /*
    Author: Sergio Govoni https://www.linkedin.com/in/sgovoni/
    Version: 1.0
    License: GNU General Public License 3.0
    Github repository: https://github.com/segovoni/sp_identity_rebirth
  */

  SET NOCOUNT ON;

  -- Check input parameters
  IF (LTRIM(RTRIM(@SchemaName)) = '')
  BEGIN
    RAISERROR(N'The parameter schema name (@SchemaName) is not specified or is empty.', 16, 1);
    RETURN;
  END;

  IF (LTRIM(RTRIM(@TableName)) = '')
  BEGIN
    RAISERROR(N'The parameter table name (@TableName) is not specified or is empty.', 16, 1);
    RETURN;
  END;

  IF NOT EXISTS (SELECT
                   ORDINAL_POSITION
                 FROM
                   INFORMATION_SCHEMA.COLUMNS
                 WHERE
                   (TABLE_SCHEMA=@SchemaName)
                   AND (TABLE_NAME=@TableName)
                   AND (COLUMN_NAME=@IdentityColumn)
                )
  BEGIN
    RAISERROR(N'The identity column has not been found.', 16, 1);
    RETURN;
  END;

  DECLARE
    @PrimaryKeyColumnName SYSNAME = ''
    ,@PrimaryKeyName SYSNAME = ''
    ,@IdentityColumnIsPrimaryKey BIT = 0;

  -- Get the primary key column name
  SELECT
    @PrimaryKeyColumnName = col.name
    ,@PrimaryKeyName = idx.name
  FROM
    sys.indexes idx
  JOIN
    sys.index_columns idxcol ON idx.object_id = idxcol.object_id AND idx.index_id = idxcol.index_id
  JOIN
    sys.columns col ON idxcol.object_id = col.object_id AND idxcol.column_id = col.column_id
  WHERE
    idx.object_id = OBJECT_ID(@TableName)
    AND idx.is_primary_key = 1;
    
  IF (LTRIM(RTRIM(@IdentityColumn)) = @PrimaryKeyColumnName)
    SET @IdentityColumnIsPrimaryKey = 1
  ELSE
    SET @IdentityColumnIsPrimaryKey = 0;
  
  IF (@IdentityColumnIsPrimaryKey = 0)
  BEGIN
    RAISERROR(N'Nowadays, the identity must be on the primary key.', 16, 1);
    RETURN;
  END;

  -- Begin the identity rebirth process
  BEGIN TRY
    DECLARE
      -- SQL command table
      @SQLCmd2IdentityRebirth TABLE
	    (
        ID INTEGER IDENTITY(1, 1) NOT NULL
        ,SchemaName SYSNAME NOT NULL
        ,TableName SYSNAME NOT NULL
        ,ObjectType SYSNAME NOT NULL
        ,OperationType NCHAR(1) NOT NULL
        ,OperationOrder INTEGER NOT NULL
        ,SQLCmd NVARCHAR(1024) NOT NULL
      );

    DECLARE
      @TranCount INTEGER = @@TRANCOUNT
      ,@SQL NVARCHAR(MAX) = ''
      ,@FieldList VARCHAR(MAX) = QUOTENAME('Old_' + @IdentityColumn) +', ';

    IF (@TranCount = 0)
      -- Open an explicit transaction to avoid auto commits
      BEGIN TRANSACTION
  
    -- Drop foreign key
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    SELECT
      schemap.name AS SchemaName
      ,objp.name AS TableName
      ,'FK' AS ObjectType
      ,'D' AS OperationType
      ,1 AS OperationOrder
      ,(
        'ALTER TABLE [' + RTRIM(schemap.name) + '].[' + RTRIM(objp.name) + '] ' +
        'DROP CONSTRAINT [' + RTRIM(constr.name) + '];'
       ) AS SQLCmd
    FROM
      sys.foreign_key_columns AS fkc
    JOIN
      sys.objects AS objp ON objp.object_id=fkc.parent_object_id
    JOIN
      sys.schemas AS schemap ON objp.schema_id=schemap.schema_id
    JOIN
      sys.objects AS objr ON objr.object_id=fkc.referenced_object_id
    JOIN
      sys.schemas AS schemar ON objr.schema_id=schemar.schema_id
    JOIN
      sys.columns AS colr ON colr.column_id=fkc.referenced_column_id and colr.object_id=fkc.referenced_object_id
    JOIN
      sys.columns AS colp ON colp.column_id=fkc.parent_column_id and colp.object_id=fkc.parent_object_id
    JOIN
      sys.objects AS constr ON constr.object_id=fkc.constraint_object_id
    WHERE
      ((schemar.name=@SchemaName) AND (objr.name=@TableName) AND (colr.name=@IdentityColumn) AND (objr.type='U')) OR
      ((schemap.name=@SchemaName) AND (objp.name=@TableName) AND (colp.name=@IdentityColumn) AND (objr.type='U'));
  
    -- Add a temporary column to store the new compacted identity values
    SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' ADD ' + QUOTENAME('Old_' + @IdentityColumn) + ' INT;';
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    VALUES (@SchemaName, @TableName, 'TABLE', 'A', 2, @SQL);

    -- Update the temporary column with the current identity values
    SET @SQL = 'UPDATE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' SET ' + QUOTENAME('Old_' + @IdentityColumn) + ' = ' + QUOTENAME(@IdentityColumn) + ';';
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    VALUES (@SchemaName, @TableName, 'TABLE', 'U', 3, @SQL);

    -- Drop the backup table if it exists
    SET @SQL = 'IF (OBJECT_ID(''' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName + '_Backup_sp_identity_rebirth') + ''', ''U'')) IS NOT NULL ' +
                 'DROP TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName + '_Backup_sp_identity_rebirth') + ';';
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    VALUES (@SchemaName, @TableName, 'TABLE', 'D', 4, @SQL);

    -- Backup the original table   
    SET @SQL = 'SELECT ' +
                 '* ' +
               'INTO ' +
                  QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName + '_Backup_sp_identity_rebirth') + ' ' +
               'FROM ' +
                  QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    VALUES (@SchemaName, @TableName, 'TABLE', 'I', 5, @SQL);

    -- Truncate the original table
    SET @SQL = 'TRUNCATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    VALUES (@SchemaName, @TableName, 'TABLE', 'T', 6, @SQL);

    -- Construct the field list
    SELECT
      @FieldList = @FieldList + QUOTENAME(COLUMN_NAME) + ', ' 
    FROM
      INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @SchemaName)
      AND (TABLE_NAME = @TableName)
      AND (COLUMN_NAME <> @IdentityColumn)
    ORDER BY
      ORDINAL_POSITION;

    -- Insert data into the original table from the backup table
    SET @SQL = 'INSERT INTO ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' (' + SUBSTRING(@FieldList, 1, LEN(@FieldList)-1) + ') ' +
               'SELECT ' + SUBSTRING(@FieldList, 1, LEN(@FieldList)-1)  + ' FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName + '_Backup_sp_identity_rebirth') + ';';
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    VALUES (@SchemaName, @TableName, 'TABLE', 'I', 7, @SQL);

    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    SELECT
      schemap.name AS SchemaName
      ,objp.name AS TableName
      ,'TABLE' AS ObjectType
      ,'U' AS OperationType
      ,8 AS OperationOrder
      --,schemap.name as schemap_name
      --,objp.name as objp_name
      --,colp.name as colp_name
      --,schemar.name as schemar_name
      --,objr.name as objr_name
      --,colr.name as colr_name
      ,(
        'UPDATE PARENT SET ' + QUOTENAME(colp.name) + ' = X.' + QUOTENAME(@IdentityColumn) + ' ' + 
        'FROM ' +
           QUOTENAME(schemap.name) + '.' + QUOTENAME(objp.name) + ' AS PARENT ' + 
        'JOIN ' + QUOTENAME(schemap.name) + '.' + QUOTENAME(objr.name) + ' AS X on X.' + QUOTENAME('Old_' + @IdentityColumn) + ' = PARENT.' + QUOTENAME(colp.name) + ';'
      ) AS SQLCmd
    FROM
      sys.foreign_key_columns AS fkc
    JOIN
      sys.foreign_keys AS fk ON fkc.constraint_object_id=fk.object_id
    JOIN
      sys.objects AS objp ON objp.object_id=fkc.parent_object_id
    JOIN
      sys.schemas AS schemap ON objp.schema_id=schemap.schema_id
    JOIN
      sys.objects AS objr ON objr.object_id=fkc.referenced_object_id
    JOIN
      sys.schemas AS schemar ON objr.schema_id=schemar.schema_id
    JOIN
      sys.columns AS colr ON colr.column_id=fkc.referenced_column_id and colr.object_id=fkc.referenced_object_id
    JOIN
      sys.columns AS colp ON colp.column_id=fkc.parent_column_id and colp.object_id=fkc.parent_object_id
    JOIN
      sys.objects AS constr ON constr.object_id=fkc.constraint_object_id
    WHERE
      ((schemar.name=@SchemaName) AND (objr.name=@TableName) AND (colr.name=@IdentityColumn) AND (objr.type='U')) OR
      ((schemap.name=@SchemaName) AND (objp.name=@TableName) AND (colp.name=@IdentityColumn) AND (objr.type='U'));

    -- Create foreign key
    INSERT INTO @SQLCmd2IdentityRebirth
    (
      SchemaName
      ,TableName
      ,ObjectType
      ,OperationType
      ,OperationOrder
      ,SQLCmd
    )
    SELECT
      schemap.name AS SchemaName
      ,objp.name AS TableName
      ,'FK' AS ObjectType
      ,'C' AS OperationType
      ,9 AS OperationOrder
      ,(
        'ALTER TABLE [' + RTRIM(schemap.name) + '].[' + RTRIM(objp.name) + '] ' +
        CASE (fk.is_not_trusted)
          WHEN 0 THEN 'WITH CHECK ADD CONSTRAINT [' + RTRIM(constr.name) + '] '
          WHEN 1 THEN 'WITH NOCHECK ADD CONSTRAINT [' + RTRIM(constr.name) + '] '
        END +
        'FOREIGN KEY ([' + RTRIM(colp.name) + '])' + ' ' +
        'REFERENCES [' + RTRIM(schemar.name) + '].[' + RTRIM(objr.name) + ']([' + RTRIM(colr.name) + ']);'
       ) AS SQLCmd
    FROM
      sys.foreign_key_columns AS fkc
    JOIN
      sys.foreign_keys AS fk ON fkc.constraint_object_id=fk.object_id
    JOIN
      sys.objects AS objp ON objp.object_id=fkc.parent_object_id
    JOIN
      sys.schemas AS schemap ON objp.schema_id=schemap.schema_id
    JOIN
      sys.objects AS objr ON objr.object_id=fkc.referenced_object_id
    JOIN
      sys.schemas AS schemar ON objr.schema_id=schemar.schema_id
    JOIN
      sys.columns AS colr ON colr.column_id=fkc.referenced_column_id and colr.object_id=fkc.referenced_object_id
    JOIN
      sys.columns AS colp ON colp.column_id=fkc.parent_column_id and colp.object_id=fkc.parent_object_id
    JOIN
      sys.objects AS constr ON constr.object_id=fkc.constraint_object_id
    WHERE
      ((schemar.name=@SchemaName) AND (objr.name=@TableName) AND (colr.name=@IdentityColumn) AND (objr.type='U')) OR
      ((schemap.name=@SchemaName) AND (objp.name=@TableName) AND (colp.name=@IdentityColumn) AND (objr.type='U'));

    SELECT
      *
    FROM
      @SQLCmd2IdentityRebirth
    ORDER BY
      OperationOrder;

    -- Cursor to loop through each command
    DECLARE C_SQL_CMD CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
      SELECT
        SQLCmd
      FROM
        @SQLCmd2IdentityRebirth
      ORDER BY
        OperationOrder;

    OPEN C_SQL_CMD;

    -- First fetch
    FETCH NEXT FROM C_SQL_CMD INTO @SQL;

    -- Execute each step
    WHILE (@@FETCH_STATUS=0)
    BEGIN
      PRINT(@SQL);
      EXEC(@SQL);
      FETCH NEXT FROM C_SQL_CMD INTO @SQL;
    END;
    
    CLOSE C_SQL_CMD;
    DEALLOCATE C_SQL_CMD;      

    PRINT 'Identity column rebirth completed successfully.';

    -- If no previous transaction, commit the current transaction
    IF (@TranCount = 0) AND (@@ERROR = 0)
      COMMIT TRANSACTION;

    SET NOCOUNT OFF;
  END TRY
  BEGIN CATCH
    -- Rollback transaction in case of error
    IF (@TranCount = 0) -- AND (XACT_STATE() <> 0)  -- check this XACT_STATE() <> 0
      ROLLBACK TRANSACTION;

    -- Error handling
    DECLARE
      @ErrorMessage NVARCHAR(MAX)
      ,@ErrorSeverity INTEGER
      ,@ErrorState INTEGER;

    SELECT 
      @ErrorMessage = ERROR_MESSAGE()
      ,@ErrorSeverity = ERROR_SEVERITY()
      ,@ErrorState = ERROR_STATE();

    SET NOCOUNT OFF;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
  END CATCH
END;
GO