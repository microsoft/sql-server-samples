-- Demonstrate Row Level Security -- Window 2


-- Right-click this query window and change connection
-- Log on as SQL login Website with password SQLRocks!00

-- Ensure we are logged on as the website user

SELECT SUSER_SNAME();
GO

-- Note that no customers are visible as yet
SELECT * FROM Sales.Customers;
GO

-- Set the session context (the website would set this on behalf of the user)
EXEC sp_set_session_context N'SalesTerritory', N'Great Lakes', @read_only = 1;
GO

-- Check the value that was set
SELECT SESSION_CONTEXT(N'SalesTerritory');
GO

-- Note that the user can now access the users based upon the sales territory in the session_context
SELECT * FROM Sales.Customers;
GO

USE tempdb;
GO

-- Right-click this window and from the connection menu, disconnect

-- Switch back to the main window to tidy up