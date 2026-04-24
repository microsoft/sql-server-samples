-- =============================================
-- Create Public Key Certificate Template
-- =============================================

CREATE CERTIFICATE <certificate_name, sysname, test_cert>
   AUTHORIZATION <user-name, sysname, test_user>
   FROM  FILE = '<path_to_certificate, varchar, C:\mycert>'

