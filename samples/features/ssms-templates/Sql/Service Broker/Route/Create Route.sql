-- =============================================
-- Basic Create Route Template
-- =============================================

CREATE ROUTE <route_name, sysname, test_route>
WITH
     SERVICE_NAME = N'<service-name, nvarchar, test_service>',
     BROKER_INSTANCE =
	N'<broker-instance, nvarchar, 62BC1928-7A4A-4EFD-B72C-E6E9647A5077>' ,
     ADDRESS = N'<next-hop-address, nvarchar, TCP://mycomputer.mydomain:4022>'
