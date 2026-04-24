
-- =============================================
-- Create Anonymous Remote Service Binding Template
-- =============================================

CREATE REMOTE SERVICE BINDING [<binding-name, sysname, test_binding>]
  TO SERVICE N'<service-name, nvarchar, test_service>'
  WITH USER = [<user-name, sysname, test_user>], ANONYMOUS = ON

