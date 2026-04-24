
-- =============================================
-- Change Route Address Template
-- =============================================

ALTER ROUTE <route-name, sysname, test_route> WITH
     ADDRESS = N'<next-hop-address, nvarchar, TCP://mycomputer.mydomain:4022>'

