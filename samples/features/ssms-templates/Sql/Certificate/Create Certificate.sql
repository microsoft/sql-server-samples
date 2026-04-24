--=================================
-- Create certificate template
--=================================
IF EXISTS(
  SELECT *
    FROM sys.certificates
   WHERE name = N'<certificate_name, sysname, sample_certificate>'
)
DROP CERTIFICATE <certificate_name, sysname, sample_certificate>
GO

CREATE CERTIFICATE <certificate_name, sysname, sample_certificate>
	ENCRYPTION BY PASSWORD = <certificate_password, sysname, '1()ds5274-785$0HA05432-22379;}'>
	WITH SUBJECT = <certificate_subject, sysname, 'MySampleCertificate'>;
GO
