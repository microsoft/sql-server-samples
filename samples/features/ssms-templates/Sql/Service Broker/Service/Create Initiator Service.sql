
-- =============================================
-- Basic Create Initiator Service Template
-- =============================================

-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE SERVICE [<service-name, sysname, test_service>]
AUTHORIZATION <owner-name ,database-user  ,dbo>
ON QUEUE <queue-name, sysname, test_queue>
([DEFAULT])
