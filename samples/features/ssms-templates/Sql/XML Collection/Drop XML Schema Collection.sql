-- =============================================
-- Drop XML Schema Collection Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.xml_schema_collections
            WHERE name = N'<xml_schema_collection_name, sysname, mySchemaCollection>')
DROP XML SCHEMA COLLECTION <xml_schema_collection_name, sysname, mySchemaCollection>
GO