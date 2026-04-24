-- Demonstrate Row Level Security

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'GreatLakesUser')
BEGIN
	CREATE LOGIN GreatLakesUser
	WITH PASSWORD = N'SQLRocks!00',
	     CHECK_POLICY = OFF,
		 CHECK_EXPIRATION = OFF,
		 DEFAULT_DATABASE = WideWorldImporters;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'Website')
BEGIN
	CREATE LOGIN Website
	WITH PASSWORD = N'SQLRocks!00',
	     CHECK_POLICY = OFF,
		 CHECK_EXPIRATION = OFF,
		 DEFAULT_DATABASE = WideWorldImporters;
END;
GO

USE WideWorldImporters;
GO

CREATE USER GreatLakesUser FOR LOGIN GreatLakesUser;
GO

CREATE USER Website FOR LOGIN Website;
GO

ALTER ROLE [Great Lakes Sales] ADD MEMBER GreatLakesUser;
GO

-- Ensure that the policy has been applied
EXEC [Application].Configuration_ApplyRowLevelSecurity;
GO

-- The function that has been applied is as follows:
--
-- CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
-- RETURNS TABLE
-- WITH SCHEMABINDING
-- AS
-- RETURN (SELECT 1 AS AccessResult
--         WHERE IS_ROLEMEMBER(N'db_owner') <> 0
--         OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
--                           FROM [Application].Cities AS c
--                           INNER JOIN [Application].StateProvinces AS sp
--                           ON c.StateProvinceID = sp.StateProvinceID
--                           WHERE c.CityID = @CityID) + N' Sales') <> 0
-- 	    OR (ORIGINAL_LOGIN() = N'Website'
-- 		    AND EXISTS (SELECT 1
-- 		                FROM [Application].Cities AS c
-- 				        INNER JOIN [Application].StateProvinces AS sp
-- 				        ON c.StateProvinceID = sp.StateProvinceID
-- 				        WHERE c.CityID = @CityID
-- 				        AND sp.SalesTerritory = SESSION_CONTEXT(N'SalesTerritory'))));
-- GO

-- The security policy that has been applied is as follows:
--
-- CREATE SECURITY POLICY [Application].FilterCustomersBySalesTerritoryRole
-- ADD FILTER PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
-- ON Sales.Customers,
-- ADD BLOCK PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
-- ON Sales.Customers AFTER UPDATE;
-- GO

SELECT * FROM sys.database_principals; -- not the role for Great Lakes and the user for Great Lakes
GO

SELECT * FROM Sales.Customers; -- and note count
GO

GRANT SELECT, UPDATE ON Sales.Customers TO [Great Lakes Sales];
GRANT SELECT ON [Application].Cities TO [Great Lakes Sales];
GRANT SELECT ON [Application].StateProvinces TO [Great Lakes Sales];
GRANT SELECT ON [Application].Countries TO [Great Lakes Sales];
GO

-- impersonate the user GreatLakesUser
EXECUTE AS USER = 'GreatLakesUser';
GO

-- Now note the count and which rows are returned
-- even though we have not changed the command

SELECT * FROM Sales.Customers;
GO

-- where are those customers?
-- note the spatial results tab

SELECT c.Border
FROM [Application].Countries AS c
WHERE c.CountryName = N'United States'
UNION ALL
SELECT c.DeliveryLocation
FROM Sales.Customers AS c
GO

-----------------------------------------------------------------------
-- updating rows that are accessible to a non-accessible row is blocked
-----------------------------------------------------------------------
DECLARE @GreatLakesCustomerID INT
DECLARE @NonGreatLakesCityID INT

-- pick a customer in the Great Lakes sales territory
SELECT TOP 1 @GreatLakesCustomerID=c.CustomerID
FROM Sales.Customers c JOIN Application.Cities ci ON c.DeliveryCityID=ci.CityID
	JOIN Application.StateProvinces sp ON ci.StateProvinceID=sp.StateProvinceID
WHERE sp.SalesTerritory=N'Great Lakes'

-- pick a City outside of the Great Lakes sales territory
SELECT @NonGreatLakesCityID=c.CityID
FROM Application.Cities c JOIN Application.StateProvinces sp ON c.StateProvinceID=sp.StateProvinceID
WHERE CityName=N'Seattle' AND sp.StateProvinceCode=N'WA'

UPDATE Sales.Customers                    -- Attempt to update
SET DeliveryCityID = @NonGreatLakesCityID -- to a city that is not in the Great Lakes Sales Territory
WHERE CustomerID = @GreatLakesCustomerID; -- for a customer that is in the Great Lakes Sales Territory
GO

-- revert the impersonation
REVERT;
GO

-- Remove the user from the role
ALTER ROLE [Great Lakes Sales] DROP MEMBER GreatLakesUser;
GO

-- Instead of permission for a role, let's give permissions to the website user
GRANT SELECT, UPDATE ON Sales.Customers TO [Website];
GRANT SELECT ON [Application].Cities TO [Website];
GRANT SELECT ON [Application].Countries TO [Website];
GO

-- Open the second RLS demo window and follow the instructions there

-- Finally, tidy up (optional)
/*
REVOKE SELECT, UPDATE ON Sales.Customers FROM [Great Lakes Sales];
REVOKE SELECT ON [Application].Cities FROM [Great Lakes Sales];
REVOKE SELECT ON [Application].Countries FROM [Great Lakes Sales];
REVOKE SELECT, UPDATE ON Sales.Customers FROM [Website];
REVOKE SELECT ON [Application].Cities FROM [Website];
REVOKE SELECT ON [Application].Countries FROM [Website];
GO

DROP USER GreatLakesUser;
GO

DROP USER Website;
GO

USE master;
GO

DROP LOGIN GreatLakesUser;
GO

DROP LOGIN Website;
GO


*/