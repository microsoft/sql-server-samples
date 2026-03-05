-- ========================================================================
-- Alter external data source template for Azure Synapse Analytics Database 
-- ========================================================================

ALTER EXTERNAL DATA SOURCE <data_source_name, sysname, sample_data_source> SET
	LOCATION = N'<location, sysname, sample_location>',
	RESOURCE_MANAGER_LOCATION = N'<resource_manager_location, sysname, sample_resource_manager_location>',
	CREDENTIAL = <credential_name, sysname, sample_credential>
GO