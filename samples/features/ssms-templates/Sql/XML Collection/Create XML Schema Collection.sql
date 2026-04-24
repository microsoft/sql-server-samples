-- =============================================
-- Create XML Schema Collection Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.xml_schema_collections
            WHERE name = N'<xml_schema_collection_name, sysname, mySchemaCollection>')
DROP XML SCHEMA COLLECTION <xml_schema_collection_name, sysname, mySchemaCollection>
GO

CREATE XML SCHEMA COLLECTION <xml_schema_collection_name, sysname, mySchemaCollection>
AS
'<xml_schemas, string, string_containing_xml_schemas>'
GO