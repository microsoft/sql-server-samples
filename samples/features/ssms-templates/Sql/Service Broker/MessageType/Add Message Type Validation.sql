
-- =============================================
-- Add Validation to Message Type Template
-- =============================================

ALTER MESSAGE TYPE <message-type-name, sysname, test_msg> VALIDATION =
    VALID_XML WITH SCHEMA COLLECTION <schema-collection_name, sysname, test_schema>

