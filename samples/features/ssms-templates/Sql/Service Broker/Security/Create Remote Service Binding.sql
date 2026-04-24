-- =============================================
-- Basic Create Remote Service Binding Template
-- =============================================

-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE REMOTE SERVICE BINDING [<binding-name, sysname, test_binding>]
  AUTHORIZATION <owner-name ,database-user  ,dbo>
  TO SERVICE N'<service-name, nvarchar, test_service>'
  WITH USER = [<user-name, sysname, test_user>]

