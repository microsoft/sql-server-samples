--=================================
-- Drop certificate template
--=================================
IF EXISTS(
  SELECT *
    FROM sys.certificates
   WHERE name = N'<certificate_name, sysname, sample_certificate>'
)
DROP CERTIFICATE <certificate_name, sysname, sample_certificate>
GO
