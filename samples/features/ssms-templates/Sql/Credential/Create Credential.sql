--=================================
-- Create credential template
--=================================
IF EXISTS(
  SELECT *
    FROM sys.credentials
   WHERE name = N'<credential_name, sysname, sample_credential>'
)
DROP CREDENTIAL <credential_name, sysname, sample_credential>
GO

CREATE CREDENTIAL <credential_name, sysname, sample_credential>
	WITH IDENTITY = <identity_name, sysname, 'sample_identity'>
	FOR CRYPTOGRAPHIC_PROVIDER <cryptographic_provider_name, sysname, sample_provider>
GO