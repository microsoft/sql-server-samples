
-- =============================================
-- Basic Create Route to Database Mirror Template
-- =============================================

-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE ROUTE <route-name, sysname, test_route>
AUTHORIZATION <owner-name ,database-user  ,dbo>
WITH
     SERVICE_NAME = N'<service-name, nvarchar, test_service>',
     BROKER_INSTANCE =
	N'<broker-instance, nvarchar, >' ,
	LIFETIME = <Lifetime, int, 86400> ,
     ADDRESS = N'<next-hop-address, nvarchar, TCP://mycomputer.mydomain:4022>',
     MIRROR_ADDRESS = N'<mirror-address, nvarchar, TCP://mycomputer2.mydomain:4022>'

