-------------------------------------------
-- version 0.0.0-1006
-- update hash index bucket counts based on scale factor. The script was created for scale factor 100, which corresponds to an in-memory footprint ~20GB.
-------------------------------------------

USE InMemDB
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- CUSTOMER Table
CREATE TABLE dbo.Customer(
    C_ID        bigint          NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 2000000),
    C_L_NAME    varchar(25)     COLLATE Latin1_General_100_BIN2,
    C_F_NAME    varchar(20)     COLLATE Latin1_General_100_BIN2,
	C_EMAIL     varchar(50)     NULL

) WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA )
GO

-- FULFILLMENT Table
CREATE TABLE    dbo.Fulfillment(
    FM_ID       bigint          IDENTITY(1,1)  NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 10000000),
    FM_O_ID     bigint          NOT NULL,
	FM_C_ID     bigint          NOT NULL,
	FM_DTS      datetime        NOT NULL

) WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA )
GO

-- ORDERLINES Table
CREATE TABLE    dbo.OrderLines(
    OL_O_ID     bigint          NOT NULL,
    OL_SEQ      int             NOT NULL,
    OL_PR_ID    bigint          NOT NULL,
	OL_QTY      int             NOT NULL,
	OL_PRICE    decimal(9,2)    NOT NULL,
	OL_DTS      datetime        NOT NULL,

	CONSTRAINT PK_OrderLInes PRIMARY KEY NONCLUSTERED HASH ( OL_O_ID, OL_SEQ )
		WITH (BUCKET_COUNT =  50000000),

	 INDEX IX_OrderLinesOL_O_ID HASH (OL_O_ID) WITH (BUCKET_COUNT = 50000000)

) WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA )
GO

-- ORDERS Table
CREATE TABLE dbo.Orders(
    O_ID        bigint          IDENTITY(1,1)   NOT NULL,
	O_C_ID      bigint          NOT NULL INDEX IX_Orders_O_C_ID HASH WITH (BUCKET_COUNT = 10000000),
	O_TOTAL     decimal(9,2)    NOT NULL,
	O_DTS       datetime        NOT NULL,
    O_FM_DTS    datetime		NOT NULL,

	CONSTRAINT PK_Orders PRIMARY KEY NONCLUSTERED HASH ( O_ID )
		WITH (BUCKET_COUNT =  10000000),

	INDEX IX_Orders_DTS (O_FM_DTS, O_DTS ASC)
	
) WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA )
GO

-- PRODUCTs Table
CREATE TABLE dbo.Products(
	PR_ID       bigint          NOT NULL,
	PR_NAME     varchar(50)     COLLATE Latin1_General_100_BIN2 NOT NULL,
	PR_TYPE     int				NOT NULL,
	PR_DESC     varchar(1000)   COLLATE Latin1_General_100_BIN2 NOT NULL,
	PR_PRICE    decimal(9,2)    NOT NULL,
	PR_DEC1     float           NOT NULL,
	PR_DEC2     float           NOT NULL,
	PR_DEC3     float           NOT NULL,
	PR_DEC4     float           NOT NULL,
	PR_DEC5     float           NOT NULL,
	PR_DEC6     float           NOT NULL,
	PR_DEC7     float           NOT NULL,
	PR_DEC8     float           NOT NULL,
	PR_DEC9     float           NOT NULL,
	PR_DEC10    float           NOT NULL,
	PR_DEC11    float           NOT NULL,
	PR_DEC12    float           NOT NULL,
	PR_DEC13    float           NOT NULL,
	PR_DEC14    float           NOT NULL,
	PR_DEC15    float           NOT NULL,
	PR_DEC16    float           NOT NULL,
	PR_DEC17    float           NOT NULL,
	PR_DEC18    float           NOT NULL,
	PR_DEC19    float           NOT NULL,
	PR_DEC20    float           NOT NULL,
    PR_DEC21    float           NOT NULL,
    PR_DEC22    float           NOT NULL,
    PR_DEC23    float           NOT NULL,
    PR_DEC24    float           NOT NULL,
    PR_DEC25    float           NOT NULL,
    PR_DEC26    float           NOT NULL,
    PR_DEC27    float           NOT NULL,
    PR_DEC28    float           NOT NULL,
    PR_DEC29    float           NOT NULL,
    PR_DEC30    float           NOT NULL,
    PR_DEC31    float           NOT NULL,
    PR_DEC32    float           NOT NULL,
    PR_DEC33    float           NOT NULL,
    PR_DEC34    float           NOT NULL,
    PR_DEC35    float           NOT NULL,
    PR_DEC36    float           NOT NULL,
    PR_DEC37    float           NOT NULL,
    PR_DEC38    float           NOT NULL,
    PR_DEC39    float           NOT NULL,
    PR_DEC40    float           NOT NULL,
    PR_DEC41    float           NOT NULL,
    PR_DEC42    float           NOT NULL,
    PR_DEC43    float           NOT NULL,
    PR_DEC44    float           NOT NULL,
    PR_DEC45    float           NOT NULL,
    PR_DEC46    float           NOT NULL,
    PR_DEC47    float           NOT NULL,
    PR_DEC48    float           NOT NULL,
    PR_DEC49    float           NOT NULL,
    PR_DEC50    float           NOT NULL,
    PR_DEC51    float           NOT NULL,
    PR_DEC52    float           NOT NULL,
    PR_DEC53    float           NOT NULL,
    PR_DEC54    float           NOT NULL,
    PR_DEC55    float           NOT NULL,
    PR_DEC56    float           NOT NULL,
    PR_DEC57    float           NOT NULL,
    PR_DEC58    float           NOT NULL,
    PR_DEC59    float           NOT NULL,
    PR_DEC60    float           NOT NULL,
    PR_DEC61    float           NOT NULL,
    PR_DEC62    float           NOT NULL,
    PR_DEC63    float           NOT NULL,
    PR_DEC64    float           NOT NULL,
    PR_DEC65    float           NOT NULL,
    PR_DEC66    float           NOT NULL,
    PR_DEC67    float           NOT NULL,
    PR_DEC68    float           NOT NULL,
    PR_DEC69    float           NOT NULL,
    PR_DEC70    float           NOT NULL,
    PR_DEC71    float           NOT NULL,
    PR_DEC72    float           NOT NULL,
    PR_DEC73    float           NOT NULL,
    PR_DEC74    float           NOT NULL,
    PR_DEC75    float           NOT NULL,
    PR_DEC76    float           NOT NULL,
    PR_DEC77    float           NOT NULL,
    PR_DEC78    float           NOT NULL,
    PR_DEC79    float           NOT NULL,
    PR_DEC80    float           NOT NULL,
    PR_DEC81    float           NOT NULL,
    PR_DEC82    float           NOT NULL,
    PR_DEC83    float           NOT NULL,
    PR_DEC84    float           NOT NULL,
    PR_DEC85    float           NOT NULL,
    PR_DEC86    float           NOT NULL,
    PR_DEC87    float           NOT NULL,
    PR_DEC88    float           NOT NULL,
    PR_DEC89    float           NOT NULL,
    PR_DEC90    float           NOT NULL,
    PR_DEC91    float           NOT NULL,
    PR_DEC92    float           NOT NULL,
    PR_DEC93    float           NOT NULL,
    PR_DEC94    float           NOT NULL,
    PR_DEC95    float           NOT NULL,
    PR_DEC96    float           NOT NULL,
    PR_DEC97    float           NOT NULL,
    PR_DEC98    float           NOT NULL,
    PR_DEC99    float           NOT NULL,
    PR_DEC100   float           NOT NULL,

    CONSTRAINT PK_Products PRIMARY KEY NONCLUSTERED HASH ( PR_ID )
		WITH (BUCKET_COUNT =   20000000),

    INDEX IX_Products_PR_ID NONCLUSTERED (PR_ID),

    INDEX  Products_TYPE (PR_TYPE ASC)

) WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA )
GO

-- PURCHASE_CRITERIA Table
CREATE TABLE dbo.Purchase_Criteria(
	PC_ID       bigint          NOT NULL,
	PC_DEC1     float           NOT NULL,
	PC_DEC2     float           NOT NULL,
	PC_DEC3     float           NOT NULL,
	PC_DEC4     float           NOT NULL,
	PC_DEC5     float           NOT NULL,
	PC_DEC6     float           NOT NULL,
	PC_DEC7     float           NOT NULL,
	PC_DEC8     float           NOT NULL,
	PC_DEC9     float           NOT NULL,
	PC_DEC10    float           NOT NULL,
	PC_DEC11    float           NOT NULL,
	PC_DEC12    float           NOT NULL,
	PC_DEC13    float           NOT NULL,
	PC_DEC14    float           NOT NULL,
	PC_DEC15    float           NOT NULL,
	PC_DEC16    float           NOT NULL,
	PC_DEC17    float           NOT NULL,
	PC_DEC18    float           NOT NULL,
	PC_DEC19    float           NOT NULL,
	PC_DEC20    float           NOT NULL,
    PC_DEC21    float           NOT NULL,
    PC_DEC22    float           NOT NULL,
    PC_DEC23    float           NOT NULL,
    PC_DEC24    float           NOT NULL,
    PC_DEC25    float           NOT NULL,
    PC_DEC26    float           NOT NULL,
    PC_DEC27    float           NOT NULL,
    PC_DEC28    float           NOT NULL,
    PC_DEC29    float           NOT NULL,
    PC_DEC30    float           NOT NULL,
    PC_DEC31    float           NOT NULL,
    PC_DEC32    float           NOT NULL,
    PC_DEC33    float           NOT NULL,
    PC_DEC34    float           NOT NULL,
    PC_DEC35    float           NOT NULL,
    PC_DEC36    float           NOT NULL,
    PC_DEC37    float           NOT NULL,
    PC_DEC38    float           NOT NULL,
    PC_DEC39    float           NOT NULL,
    PC_DEC40    float           NOT NULL,
    PC_DEC41    float           NOT NULL,
    PC_DEC42    float           NOT NULL,
    PC_DEC43    float           NOT NULL,
    PC_DEC44    float           NOT NULL,
    PC_DEC45    float           NOT NULL,
    PC_DEC46    float           NOT NULL,
    PC_DEC47    float           NOT NULL,
    PC_DEC48    float           NOT NULL,
    PC_DEC49    float           NOT NULL,
    PC_DEC50    float           NOT NULL,
    PC_DEC51    float           NOT NULL,
    PC_DEC52    float           NOT NULL,
    PC_DEC53    float           NOT NULL,
    PC_DEC54    float           NOT NULL,
    PC_DEC55    float           NOT NULL,
    PC_DEC56    float           NOT NULL,
    PC_DEC57    float           NOT NULL,
    PC_DEC58    float           NOT NULL,
    PC_DEC59    float           NOT NULL,
    PC_DEC60    float           NOT NULL,
    PC_DEC61    float           NOT NULL,
    PC_DEC62    float           NOT NULL,
    PC_DEC63    float           NOT NULL,
    PC_DEC64    float           NOT NULL,
    PC_DEC65    float           NOT NULL,
    PC_DEC66    float           NOT NULL,
    PC_DEC67    float           NOT NULL,
    PC_DEC68    float           NOT NULL,
    PC_DEC69    float           NOT NULL,
    PC_DEC70    float           NOT NULL,
    PC_DEC71    float           NOT NULL,
    PC_DEC72    float           NOT NULL,
    PC_DEC73    float           NOT NULL,
    PC_DEC74    float           NOT NULL,
    PC_DEC75    float           NOT NULL,
    PC_DEC76    float           NOT NULL,
    PC_DEC77    float           NOT NULL,
    PC_DEC78    float           NOT NULL,
    PC_DEC79    float           NOT NULL,
    PC_DEC80    float           NOT NULL,
    PC_DEC81    float           NOT NULL,
    PC_DEC82    float           NOT NULL,
    PC_DEC83    float           NOT NULL,
    PC_DEC84    float           NOT NULL,
    PC_DEC85    float           NOT NULL,
    PC_DEC86    float           NOT NULL,
    PC_DEC87    float           NOT NULL,
    PC_DEC88    float           NOT NULL,
    PC_DEC89    float           NOT NULL,
    PC_DEC90    float           NOT NULL,
    PC_DEC91    float           NOT NULL,
    PC_DEC92    float           NOT NULL,
    PC_DEC93    float           NOT NULL,
    PC_DEC94    float           NOT NULL,
    PC_DEC95    float           NOT NULL,
    PC_DEC96    float           NOT NULL,
    PC_DEC97    float           NOT NULL,
    PC_DEC98    float           NOT NULL,
    PC_DEC99    float           NOT NULL,
    PC_DEC100   float           NOT NULL,

	CONSTRAINT PK_Purchase_Criteria PRIMARY KEY NONCLUSTERED HASH ( PC_ID )
		WITH (BUCKET_COUNT =  2000000)

) WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA )
GO

SET ANSI_PADDING OFF
GO


