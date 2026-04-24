/********************************************************************************************************************************************************
*
*			Functions that generate CREATE PROCEDURE script that inserts, updates, retreives, and merges
*			input JSON parameter in a table.
*			Keys in JSON object must match columns in table. Use FOR JSON to generate JSON from table.
*			Author: Jovan Popovic
*
********************************************************************************************************************************************************/

DROP SCHEMA IF EXISTS codegen
GO
CREATE SCHEMA codegen
GO

DROP FUNCTION IF EXISTS codegen.QNAME
GO
CREATE FUNCTION codegen.QNAME(@name sysname)
RETURNS NVARCHAR(300) AS
BEGIN
	RETURN(IIF(@name like '%[^a-zA-Z0-9]%', QUOTENAME(@name),@name));
END
GO
DROP FUNCTION IF EXISTS codegen.JSON_ESCAPE
GO
CREATE FUNCTION codegen.JSON_ESCAPE(@name sysname)
RETURNS NVARCHAR(300) AS
BEGIN
	RETURN(IIF(@name like '%[^a-zA-Z0-9]%', '"'+STRING_ESCAPE(@name, 'json')+'"',@name));
END
GO
DROP FUNCTION IF EXISTS codegen.GenerateProcedureHead
GO
CREATE FUNCTION codegen.GenerateProcedureHead(@Table sysname, @JsonParam sysname)
RETURNS NVARCHAR(max)
AS BEGIN

	RETURN ''

END
GO

GO
DROP FUNCTION IF EXISTS codegen.GenerateProcedureTail
GO
CREATE FUNCTION codegen.GenerateProcedureTail(@Table sysname)
RETURNS NVARCHAR(max)
AS BEGIN

	RETURN ''

END
GO
GO
DROP FUNCTION IF EXISTS
codegen.GetTableColumns
GO
CREATE FUNCTION
codegen.GetTableColumns(@SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS TABLE
AS RETURN (
	select
		col.name as ColumnName,
		col.column_id ColumnId,
		typ.name as ColumnType,
		-- create type with size based on type name and size
		case typ.name
			when 'char' then '(' + cast(col.max_length as varchar(10))+ ')'
			when 'nchar' then '(' + cast(col.max_length/2 as varchar(10))+ ')'
			when 'nvarchar' then (IIF(col.max_length=-1 or CHARINDEX(col.name, @JsonColumns,0) > 0, '(MAX)', '(' + cast(col.max_length/2 as varchar(10))+ ')'))
			when 'varbinary' then (IIF(col.max_length=-1 , '(MAX)', '(' + cast(col.max_length as varchar(10))+ ')'))
			when 'varchar' then (IIF(col.max_length=-1, '(MAX)', '(' + cast(col.max_length as varchar(10))+ ')'))
			when 'decimal' then '(' + cast(col.precision as varchar(10))+ ',' + cast(col.scale as varchar(10)) + ')'
			when 'datetimeoffset' then '(' + cast(col.scale as varchar(10))+ ')'
			when 'numeric' then '(' + cast(col.precision as varchar(10))+ ',' + cast(col.scale as varchar(10)) + ')'
			when 'datetime2' then '(' + cast(col.scale as varchar(10))+ ')'
			else ''
		end as StringSize,
		-- if column is not nullable, add Strict mode in JSON
		case
			when col.is_nullable = 1 then '$.' else 'strict $.'
		end Mode,
		CHARINDEX(col.name, @JsonColumns,0) as IsJson,
		i.is_primary_key IsPK,
		IIF(col.is_identity = 0
			and col.is_computed = 0
			and col.is_hidden = 0
			and col.is_rowguidcol = 0
			and generated_always_type = 0
			and (sm.text IS NULL OR sm.text NOT LIKE '(NEXT VALUE FOR%')
			and LOWER(typ.name) NOT IN ('text', 'ntext', 'sql_variant', 'image','hierarchyid','geometry','geography'),
			1,0) as IsDataColumn
from sys.columns col
		join sys.types typ
			on col.system_type_id = typ.system_type_id AND col.user_type_id = typ.user_type_id
			LEFT join sys.index_columns ic
				ON ic.object_id = col.object_id AND col.column_id = ic.column_id
				LEFT join sys.indexes i
					ON i.object_id = ic.object_id AND i.index_id = ic.index_id
				LEFT JOIN sys.syscomments SM ON col.default_object_id = SM.id
where col.object_id = object_id(codegen.QNAME(@SchemaName) + '.' + codegen.QNAME(@TableName))	
and col.name NOT IN (SELECT value COLLATE Latin1_General_CI_AS FROM STRING_SPLIT(@IgnoredColumns, ','))
)
GO

GO
DROP FUNCTION IF EXISTS
codegen.GetPkColumns
GO
CREATE FUNCTION
codegen.GetPkColumns(@SchemaName sysname, @TableName sysname)
RETURNS TABLE
AS RETURN (
	select * FROM codegen.GetTableColumns(@SchemaName, @TableName,'','')
	where IsPK = 1
)
GO
DROP FUNCTION IF EXISTS
codegen.GetTableDefinition
GO
CREATE FUNCTION
codegen.GetTableDefinition(@SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS TABLE
AS RETURN (
	select * FROM codegen.GetTableColumns(@SchemaName, @TableName,@JsonColumns,@IgnoredColumns)
	where IsDataColumn = 1
)
GO
GO
DROP FUNCTION IF EXISTS codegen.GetOpenJsonSchema
GO
CREATE FUNCTION codegen.GetOpenJsonSchema (@SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max), @WithPk bit = 0)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @JsonSchema NVARCHAR(MAX) = '';

with columns as (
select ColumnId, ColumnName, ColumnType, StringSize, IsJson, Mode
from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
union all
select ColumnId, ColumnName, ColumnType, StringSize, 0 as IsJson, 'strict $.' as Mode
from codegen.GetPkColumns(@SchemaName, @TableName)
where @WithPk = 1
)
SELECT @JsonSchema =
@JsonSchema + '
					' + codegen.QNAME(ColumnName) + ' ' + ColumnType + StringSize +
			 IIF(ISNULL(SESSION_CONTEXT(N'CODEGEN:EXPLICIT.JSON.PATH'),'no')='yes',
				(' N''' + Mode + codegen.JSON_ESCAPE(ColumnName) +'''' +IIF(IsJson>0, ' AS JSON', '') + ',' ),
				IIF(codegen.JSON_ESCAPE(ColumnName) <> codegen.QNAME(ColumnName) OR CHARINDEX('strict', Mode)>0,
					(' N''' + Mode + codegen.JSON_ESCAPE(ColumnName) +'''' +IIF(IsJson>0, ' AS JSON', '') + ',' ),
					IIF(IsJson>0, ' AS JSON', '') + ','))	
from columns
order by ColumnId;
RETURN @JsonSchema

END

GO
DROP FUNCTION IF EXISTS
codegen.GenerateJsonCreateProcedure
GO
CREATE FUNCTION
codegen.GenerateJsonCreateProcedure(@ProcSchemaName sysname, @SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS NVARCHAR(MAX)
AS BEGIN
declare @JsonParam sysname = '@'+@TableName+'Json'
declare @JsonSchema nvarchar(max) = codegen.GetOpenJsonSchema (@SchemaName, @TableName, @JsonColumns, @IgnoredColumns, 0);

-- Generate list of column names ordered by columnid
declare @TableSchema nvarchar(max) = '';
select @TableSchema = @TableSchema + codegen.QNAME(ColumnName) + ','
from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
order by ColumnId

SET @TableSchema = SUBSTRING(@TableSchema, 0, LEN(@TableSchema)) --> remove last comma

-- Generate list of column names ordered by columnid
declare @OutputPks nvarchar(max) = '';

select @OutputPks = @OutputPks + ' INSERTED.'+  codegen.QNAME(ColumnName) + ','
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId

SET @OutputPks = SUBSTRING(@OutputPks, 0, LEN(@OutputPks)) --> remove last comma



declare @Result nvarchar(max) =
N'GO
DROP PROCEDURE IF EXISTS ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Insert' + @TableName + 'FromJson') + '
GO
CREATE PROCEDURE ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Insert' + @TableName + 'FromJson') + '(' + @JsonParam + ' NVARCHAR(MAX))
WITH EXECUTE AS OWNER
AS BEGIN
' +
	codegen.GenerateProcedureHead(@TableName, @JsonParam)
+
'	INSERT INTO ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + '(' + @TableSchema + ')
			OUTPUT ' + @OutputPks + '
			SELECT ' + @TableSchema + '
			FROM OPENJSON(' + @JsonParam + ')
				WITH (' + @JsonSchema + ')' +
	codegen.GenerateProcedureTail(@TableName)
+
'
END'

RETURN REPLACE(@Result,',)',')')
END

GO

GO
DROP FUNCTION IF EXISTS
codegen.GenerateJsonUpdateProcedure
GO
CREATE FUNCTION
codegen.GenerateJsonUpdateProcedure(@ProcSchemaName sysname, @SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS NVARCHAR(MAX)
AS BEGIN
declare @JsonParam sysname = '@'+@TableName+'Json'
declare @JsonSchema nvarchar(max) = codegen.GetOpenJsonSchema (@SchemaName, @TableName, @JsonColumns, @IgnoredColumns, 1);

-- Generate list of column names ordered by columnid
declare @TableSchema nvarchar(max) = '';

select @TableSchema = @TableSchema + CHAR(10) + '				' +  codegen.QNAME(ColumnName) + ' = json.' +  codegen.QNAME(ColumnName) + ','
from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
order by ColumnId

SET @TableSchema = SUBSTRING(@TableSchema, 0, LEN(@TableSchema)) --> remove last comma


-- Generate list of column names ordered by columnid
declare @RowFilter nvarchar(max) = '';

select @RowFilter = @RowFilter + CHAR(10) + '				'+ codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) +'.' +  codegen.QNAME(ColumnName) + ' = json.' +  codegen.QNAME(ColumnName) + ','
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId

SET @RowFilter = SUBSTRING(@RowFilter, 0, LEN(@RowFilter)) --> remove last comma

declare @Result nvarchar(max) =
N'GO
DROP PROCEDURE IF EXISTS ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Update' + @TableName + 'FromJson') + '
GO
CREATE PROCEDURE ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Update' + @TableName + 'FromJson') +'(' + @JsonParam + ' NVARCHAR(MAX))
WITH EXECUTE AS OWNER
AS BEGIN' +
	codegen.GenerateProcedureHead(@TableName, @JsonParam)
+
'	UPDATE ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + ' SET' + @TableSchema + '
			FROM OPENJSON(' + @JsonParam + ')
				WITH (' + @JsonSchema + ') as json
			WHERE ' + @RowFilter  + '
' +
	codegen.GenerateProcedureTail(@TableName)
+
'
END'

RETURN REPLACE(@Result,',)',')')
END

GO


GO
DROP FUNCTION IF EXISTS
codegen.GenerateJsonRetrieveProcedure
GO
CREATE FUNCTION
codegen.GenerateJsonRetrieveProcedure(@ProcSchemaName sysname, @SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS NVARCHAR(MAX)
AS BEGIN

declare @Columns nvarchar(max) = '';

with all_columns(ColumnId, ColumnName, ColumnType, StringSize, IsJson, Mode) AS(
select ColumnId, ColumnName, ColumnType, StringSize, IsJson, Mode from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
union all
select ColumnId, ColumnName, ColumnType, StringSize, 0 as IsJson, 'strict $.' as Mode from codegen.GetPkColumns(@SchemaName, @TableName)
)
select @Columns = @Columns + codegen.QNAME(ColumnName) + ','-- + ColumnType + StringSize --+
			-- ' N''' + Mode + '"' + STRING_ESCAPE(ColumnName, 'json') + '"''' +IIF(IsJson>0, ' AS JSON', '') + ','
from all_columns
order by ColumnId

set @Columns = SUBSTRING(@Columns, 0, LEN(@Columns))

-- Generate list of column names ordered by columnid
declare @Parameters nvarchar(max) = '';

select @Parameters = @Parameters + '@' + ColumnName + ' ' + ColumnType + ','
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId


-- Generate list of column names ordered by columnid
declare @RowFilter nvarchar(max) = '';

select @RowFilter = @RowFilter +  codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + '.' + codegen.QNAME(ColumnName) + ' = @' +  ColumnName + ' AND '
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId

SET @RowFilter = SUBSTRING(@RowFilter, -3, LEN(@RowFilter)) --> remove last comma

declare @Result nvarchar(max) =
N'GO
DROP FUNCTION IF EXISTS ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Retrieve' + @TableName + 'AsJson') + '
GO
CREATE FUNCTION ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Retrieve' + @TableName + 'AsJson') + '(' + @Parameters + ')
RETURNS NVARCHAR(MAX)
AS BEGIN
	RETURN( SELECT ' + @Columns + '
	FROM ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + '
	WHERE ' + @RowFilter + '
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
END'

RETURN REPLACE(@Result,',)',')')
END

GO

GO
DROP FUNCTION IF EXISTS
codegen.GenerateJsonDeleteProcedure
GO
CREATE FUNCTION
codegen.GenerateJsonDeleteProcedure(@ProcSchemaName sysname, @SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS NVARCHAR(MAX)
AS BEGIN

declare @Columns nvarchar(max) = '';

with all_columns(ColumnId, ColumnName, ColumnType, StringSize, IsJson, Mode) AS(
select ColumnId, ColumnName, ColumnType, StringSize, IsJson, Mode from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
union all
select ColumnId, ColumnName, ColumnType, StringSize, 0 as IsJson, 'strict $.' as Mode from codegen.GetPkColumns(@SchemaName, @TableName)
)
select @Columns = @Columns + codegen.QNAME(ColumnName) + ','
from all_columns
order by ColumnId

-- Generate list of column names ordered by columnid
declare @Parameters nvarchar(max) = '';

select @Parameters = @Parameters + '@' + ColumnName + ' ' + ColumnType + ','
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId


-- Generate list of column names ordered by columnid
declare @RowFilter nvarchar(max) = '';

select @RowFilter = @RowFilter +  codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + '.' + codegen.QNAME(ColumnName) + ' = @' +  ColumnName + ' AND '
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId

SET @RowFilter = SUBSTRING(@RowFilter, -3, LEN(@RowFilter)) --> remove last comma

declare @Result nvarchar(max) =
N'GO
DROP PROCEDURE IF EXISTS ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME('Delete' + @TableName) + '
GO
CREATE PROCEDURE ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME('Delete' + @TableName) + '(' + @Parameters + ')
WITH EXECUTE AS OWNER
AS BEGIN
	DELETE ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + '
	WHERE ' + @RowFilter + '
END'

RETURN REPLACE(@Result,',)',')')
END

GO

GO
DROP FUNCTION IF EXISTS
codegen.GenerateJsonUpsertProcedure
GO
CREATE FUNCTION
codegen.GenerateJsonUpsertProcedure(@ProcSchemaName sysname, @SchemaName sysname, @TableName sysname, @JsonColumns nvarchar(max), @IgnoredColumns nvarchar(max))
RETURNS NVARCHAR(MAX)
AS BEGIN
declare @JsonParam sysname = '@'+@TableName+'Json'
declare @JsonSchema nvarchar(max) = codegen.GetOpenJsonSchema (@SchemaName, @TableName, @JsonColumns, @IgnoredColumns, 1);

-- Generate list of column names ordered by columnid
declare @TableSchema nvarchar(max) = '';

select @TableSchema = @TableSchema + CHAR(10) + '				' +  codegen.QNAME(ColumnName) + ','
from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
order by ColumnId

SET @TableSchema = SUBSTRING(@TableSchema, 0, LEN(@TableSchema)) --> remove last comma


-- Generate list of column names ordered by columnid
declare @TableSchemaWithAlias nvarchar(max) = '';

select @TableSchemaWithAlias = @TableSchemaWithAlias + CHAR(10) + '				json.' +  codegen.QNAME(ColumnName) + ','
from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
order by ColumnId

SET @TableSchemaWithAlias = SUBSTRING(@TableSchemaWithAlias, 0, LEN(@TableSchemaWithAlias)) --> remove last comma


declare @TableUpdateColumns nvarchar(max) = '';

select @TableUpdateColumns = @TableUpdateColumns + CHAR(10) + '				' +  codegen.QNAME(ColumnName) + ' = json.' +  codegen.QNAME(ColumnName) + ','
from codegen.GetTableDefinition(@SchemaName, @TableName, @JsonColumns, @IgnoredColumns)
order by ColumnId

SET @TableUpdateColumns = SUBSTRING(@TableUpdateColumns, 0, LEN(@TableUpdateColumns)) --> remove last comma


-- Generate list of column names ordered by columnid
declare @RowFilter nvarchar(max) = '';
declare @PkColumns nvarchar(max) = '';
declare @PkColumnsAndTypes nvarchar(max) = '';

select
@PkColumns = @PkColumns + 'INSERTED.' + codegen.QNAME(ColumnName) + ',',
@PkColumnsAndTypes = @PkColumnsAndTypes + codegen.QNAME(ColumnName) + ' INT,',
@RowFilter = @RowFilter + CHAR(10) + '		'+ codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) +'.' +  codegen.QNAME(ColumnName) + ' = json.' +  codegen.QNAME(ColumnName) + ','
from codegen.GetPkColumns(@SchemaName, @TableName)
order by ColumnId

SET @PkColumns = SUBSTRING(@PkColumns, 0, LEN(@PkColumns)) --> remove last comma
SET @PkColumnsAndTypes = SUBSTRING(@PkColumnsAndTypes, 0, LEN(@PkColumnsAndTypes)) --> remove last comma
SET @RowFilter = SUBSTRING(@RowFilter, 0, LEN(@RowFilter)) --> remove last comma

declare @Result nvarchar(max) =
N'GO
DROP PROCEDURE IF EXISTS ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Upsert' + @TableName + 'FromJson') + '
GO
CREATE PROCEDURE ' + codegen.QNAME( @ProcSchemaName) + '.' + codegen.QNAME('Upsert' + @TableName + 'FromJson') +'(' + @JsonParam + ' NVARCHAR(MAX))
WITH EXECUTE AS OWNER
AS BEGIN
' +
	codegen.GenerateProcedureHead(@TableName, @JsonParam)
+
'MERGE INTO ' + codegen.QNAME( @SchemaName) + '.' + codegen.QNAME(@TableName) + '
		USING ( SELECT *
			FROM OPENJSON(' + @JsonParam + ')
				WITH (' + @JsonSchema + ')) as json
		ON (' + @RowFilter + ')
		WHEN MATCHED THEN
			UPDATE SET' + @TableUpdateColumns +
	
	'
		WHEN NOT MATCHED THEN
			INSERT (' + @TableSchema + ')
			VALUES  (' + @TableSchemaWithAlias + ');' +
--		OUTPUT ' + @PkColumns + '
--			INTO @ChildRows;
--' +
	codegen.GenerateProcedureTail(@TableName)
+
'
END'
	

RETURN REPLACE(@Result,',)',')')
END

GO