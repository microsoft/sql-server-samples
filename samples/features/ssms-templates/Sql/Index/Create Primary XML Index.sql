-- =============================================
-- Create Primary XML Index Template
-- =============================================
-- Creates a primary XML index on an XML column.
-- It must be created before any secondary XML indexes
-- of type PATH, VALUE or PROPERTY can be created
-- on the XML column

USE	<database_name, sysname, myDatabase>
GO

IF EXISTS (
	SELECT	*
    FROM	sys.xml_indexes
    WHERE	name = '<xml_index_name, sysname, myPrimaryXmlIndex>' AND
			object_id = OBJECT_ID ('<schema_name, sysname, myDatabaseSchema>.<table_name, sysname, myTable>')
	)
DROP INDEX <xml_index_name, sysname, myPrimaryXmlIndex>
	ON <schema_name, sysname, myDatabaseSchema>.<table_name, sysname, myTable>
GO

CREATE PRIMARY XML INDEX <xml_index_name, sysname, myPrimaryXmlIndex>
ON <schema_name, sysname, myDatabaseSchema>.<table_name, sysname, myTable>
(
	<xml_column_name, sysname, myXmlColumn>
)
GO
