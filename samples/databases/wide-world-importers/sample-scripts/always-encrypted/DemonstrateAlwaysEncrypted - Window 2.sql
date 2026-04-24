-- Always Encrypted Demo - Window 2
-- This connection is used to simulate a client app

-- note this demo is continued from the first demo window

-- 5b. Right-click in this window and choose Connection, then Change Connection.
-- 5c. In the connection dialog, click Options.
-- 5d. Type WideWorldImporters for the database name.
-- 5e. Click on Additional Connection Parameters and enter: Column Encryption Setting=enabled
-- 5f. Click Connect

-- Note that when acting as a client with access to the certificate, we
-- can see the data. Remember that this can only work because
-- the client happens to be the same machine as the server in our
-- case.

SELECT * FROM Purchasing.Supplier_PrivateDetails ORDER BY SupplierID;
GO



-- Continue on the first window.
