--=================================
-- Drop credential template
--=================================
IF EXISTS(
  SELECT *
    FROM sys.credentials
   WHERE name = N'<credential_name, sysname, sample_credential>'
)
DROP CREDENTIAL <credential_name, sysname, sample_credential>
GO