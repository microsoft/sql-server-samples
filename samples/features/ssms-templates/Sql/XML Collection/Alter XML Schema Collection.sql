-- =============================================
-- Alter XML Schema Collection Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.xml_schema_collections
            WHERE name = N'<xml_schema_collection_name, sysname, mySchemaCollection>')
ALTER XML SCHEMA COLLECTION <xml_schema_collection_name, sysname, mySchemaCollection>
ADD '<xml_schemas, string, string_containing_xml_schemas>'
GO