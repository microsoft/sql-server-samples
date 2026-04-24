
-- =============================================
-- Change Mirror Route Address Template
-- =============================================

ALTER ROUTE <route-name, sysname, test_route> WITH
     MIRROR_ADDRESS = N'<mirror-address, nvarchar, TCP://mycomputer2.mydomain:4022>'


