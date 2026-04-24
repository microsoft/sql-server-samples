DROP SECURITY POLICY IF EXISTS dbo.ClientAccessPolicy
GO
DROP FUNCTION IF EXISTS dbo.pUserCanAccessCompanyData
GO

CREATE FUNCTION
dbo.pUserCanAccessCompanyData(@CompanyID int)
	RETURNS TABLE
	WITH SCHEMABINDING
AS RETURN (
	SELECT 1 as canAccess WHERE
	
	SESSION_CONTEXT(N'CompanyID') = '-1'
	OR CAST(SESSION_CONTEXT(N'CompanyID') as int) = @CompanyID)

GO

/*
TRY IT:
EXEC sp_set_session_context 'CompanyID', '-1'
select SESSION_CONTEXT(N'CompanyID')
SELECT * FROM dbo.pUserCanAccessCompanyData(1)
*/

CREATE SECURITY POLICY dbo.ClientAccessPolicy
	ADD FILTER PREDICATE dbo.pUserCanAccessCompanyData(CompanyID) ON dbo.Product
	WITH (State=ON)
GO

/*
EXEC sp_set_session_context 'CompanyID', '-1'
SELECT * FROM Product

EXEC sp_set_session_context 'CompanyID', 1
SELECT * FROM Product

EXEC sp_set_session_context 'CompanyID', 2
SELECT * FROM Product

EXEC sp_set_session_context 'CompanyID', 777
SELECT * FROM Product
*/

-- Add RLS on history data
ALTER SECURITY POLICY dbo.ClientAccessPolicy
	ADD FILTER PREDICATE dbo.pUserCanAccessCompanyData(CompanyID) ON History.Product
GO

/*
	Don't allow company to enter a product for different company.
*/
ALTER SECURITY POLICY dbo.ClientAccessPolicy
	ADD BLOCK PREDICATE dbo.pUserCanAccessCompanyData(CompanyID) ON dbo.Product
GO

/*
	Don't show other companies to current company.
*/
ALTER SECURITY POLICY dbo.ClientAccessPolicy
	ADD FILTER PREDICATE dbo.pUserCanAccessCompanyData(CompanyID) ON dbo.Company
GO