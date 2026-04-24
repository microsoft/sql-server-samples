-- =============================================
-- Create Private Key Certificate Template
-- =============================================

CREATE CERTIFICATE <certificate_name, sysname, test_cert>
   AUTHORIZATION <user-name, sysname, test_user>
   FROM  FILE = '<path_to_certificate, varchar, C:\mycert>'
   WITH PRIVATE_KEY (FILE = '<path_to_private_key, varchar, C:\mykey>', DECRYPTION_PASSWORD = '<key_password, varchar, passwd>')
