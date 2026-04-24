----------------------------------------------------------------------------
--                                                                        --
--  File:   Create_Indexes_DiskBased_Tables.SQL                           --
--  For Azure SQL DB, replace all occurenced of "ON DiskBased_fg" with "" --
--  Run this script after loading data                                    --
----------------------------------------------------------------------------
USE DiskBasedDB
GO

---
--- Set connection attributes
---
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF
GO

-- *** CUSTOMER ***
IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'PK_CUSTOMER' )
    CREATE UNIQUE CLUSTERED INDEX PK_CUSTOMER ON Customer( C_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
       ON DiskBased_fg
GO

CHECKPOINT
GO

-- *** FULFILLMENT ***
IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'PK_FULFILLMENT' )
    CREATE UNIQUE CLUSTERED INDEX PK_FULFILLMENT ON Fulfillment( FM_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
        ON DiskBased_fg
GO

CHECKPOINT
GO

-- *** ORDERLINES ***
IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'PK_ORDERLINES' )
    CREATE CLUSTERED INDEX PK_ORDERLINES ON OrderLines( OL_O_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)

GO

IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'IX_ORDERLINES_NC1' )
    CREATE UNIQUE INDEX IX_ORDERLINES_NC1 ON OrderLines( OL_O_ID, OL_SEQ )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
        ON DiskBased_fg
GO

CHECKPOINT
GO

-- *** ORDERS ***
IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'PK_ORDERS' )
    CREATE UNIQUE CLUSTERED INDEX PK_ORDERS ON Orders( O_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
        ON DiskBased_fg
GO

IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'IX_ORDERS_NC1' )
    CREATE INDEX IX_ORDERS_NC1 ON Orders( O_C_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
    	ON DiskBased_fg
GO

IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'IX_ORDERS_NC2' )
    CREATE INDEX IX_ORDERS_NC2 ON Orders( O_FM_DTS, O_DTS ASC )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
    	ON DiskBased_fg
GO

CHECKPOINT
GO

-- *** PRODUCTS ***
IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'PK_PRODUCTS' )
    CREATE UNIQUE CLUSTERED INDEX PK_PRODUCTS ON Products( PR_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
        ON DiskBased_fg
GO

CHECKPOINT
GO

IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'IX_PRODUCTS_NC1' )
    CREATE INDEX IX_PRODUCTS_NC1 ON Products( PR_TYPE )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 8)
    	ON DiskBased_fg
GO

CHECKPOINT
GO

-- *** PURCHASE_CRITERIA ***
IF NOT EXISTS ( SELECT name FROM sysindexes WHERE name = 'PK_PURCHASE_CRITERIA' )
    CREATE UNIQUE CLUSTERED INDEX PK_PURCHASE_CRITERIA ON Purchase_Criteria( PC_ID )
        WITH (FILLFACTOR = 100, SORT_IN_TEMPDB=ON, MAXDOP = 24)
        ON DiskBased_fg
GO

CHECKPOINT
GO

SET ANSI_PADDING OFF
GO


