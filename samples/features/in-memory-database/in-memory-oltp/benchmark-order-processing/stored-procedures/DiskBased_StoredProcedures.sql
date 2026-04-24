------------------------------------------------------------------
--                                                              --
--  File:                                           --
--                                                              --
------------------------------------------------------------------
SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

USE DiskBasedDB
GO

IF EXISTS ( SELECT name FROM sysobjects WHERE name = 'usp_FulfillOrders' )
    DROP PROCEDURE usp_FulfillOrders
GO

CREATE PROCEDURE dbo.usp_FulfillOrders
AS
BEGIN
    DECLARE @OrderID			bigint,
            @OrderCID			bigint,
            @FulfillmentDate	datetime = GETDATE()

    -- get the oldest order id that has not been fulfilled
    SELECT  TOP 1
            @OrderID    = O_ID,
            @OrderCID   = O_C_ID
    FROM    dbo.Orders
    WHERE   O_FM_DTS = '1900-01-01 00:00:00.000'
    ORDER   BY O_DTS ASC

    IF @OrderID IS NOT NULL
    BEGIN
        -- update the order with the fulfilment date
        UPDATE  dbo.Orders
        SET     O_FM_DTS    = @FulfillmentDate
        WHERE   O_ID        = @OrderID

        -- insert the data into the FulFillment table
        INSERT INTO dbo.Fulfillment (FM_O_ID, FM_C_ID, FM_DTS) VALUES (@OrderID, @OrderCID, @FulfillmentDate)

        SELECT  @orderID AS 'OrderID Fulfilled'
    END

END
GO


IF EXISTS ( SELECT name FROM sysobjects WHERE name = 'usp_GetOrdersByCustomerID' )
    DROP PROCEDURE usp_GetOrdersByCustomerID
GO

CREATE PROCEDURE dbo.usp_GetOrdersByCustomerID
(	@C_ID           bigint)
AS
BEGIN
    DECLARE @c_f_name       varchar(20),
            @c_l_name       varchar(25),
            @c_email        varchar(50),
            @o_id           bigint,
            @o_total        decimal(9,2),
            @o_dts          datetime


    SELECT  @c_f_name   = C_F_NAME,
            @c_l_name   = C_L_NAME,
            @c_email    = C_EMAIL
    FROM    dbo.Customer
    WHERE   C_ID        = @C_ID

    SELECT  @o_id       = O_ID,
            @o_total    = O_TOTAL,
            @o_dts      = O_DTS
    FROM    dbo.Orders
    WHERE   O_C_ID      = @c_id
    ORDER   BY O_ID ASC

    SELECT  OL_SEQ,
            OL_PR_ID,
            OL_QTY,
            OL_PRICE
    FROM    dbo.OrderLines
    WHERE   OL_O_ID = @o_id

    SELECT  @c_f_name,
            @c_l_name,
            @c_email
END

GO

IF EXISTS ( SELECT name FROM sysobjects WHERE name = 'usp_GetProductsByType' )
    DROP PROCEDURE usp_GetProductsByType
GO

CREATE PROCEDURE dbo.usp_GetProductsByType
(	@REQ_TYPE		int )
AS
BEGIN
	SELECT  TOP 10
            PR_ID,
	        PR_NAME,
	        PR_TYPE,
	        PR_DESC,
	        PR_PRICE
    FROM    dbo.Products
    WHERE   PR_TYPE = @REQ_TYPE
    ORDER   BY PR_PRICE ASC

END

GO


IF EXISTS ( SELECT name FROM sysobjects WHERE name = 'usp_GetProductsPriceByPK' )
    DROP PROCEDURE usp_GetProductsPriceByPK
GO

CREATE PROCEDURE dbo.usp_GetProductsPriceByPK
(	@LOWER_PK		bigint,
	@UPPER_PK       bigint)
AS
BEGIN
	SELECT  PR_ID,
	        PR_NAME,
	        PR_TYPE,
	        PR_DESC,
	        PR_PRICE
    FROM    dbo.Products
    WHERE   PR_ID BETWEEN @LOWER_PK AND @UPPER_PK
    ORDER   BY PR_PRICE ASC
END

GO


IF EXISTS ( SELECT name FROM sysobjects WHERE name = 'usp_InsertOrder' )
    DROP PROCEDURE usp_InsertOrder
GO

CREATE PROCEDURE [dbo].[usp_InsertOrder]
(	@C_ID               bigint,
	@OL_SEQ_1			tinyint,
	@OL_PR_ID_1			bigint,
	@OL_PR_QTY_1		int,
	@OL_SEQ_2			tinyint,
	@OL_PR_ID_2			bigint,
	@OL_PR_QTY_2		int,
	@OL_SEQ_3			tinyint,
	@OL_PR_ID_3			bigint,
	@OL_PR_QTY_3		int,
	@OL_SEQ_4			tinyint,
	@OL_PR_ID_4			bigint,
	@OL_PR_QTY_4		int,
	@OL_SEQ_5			tinyint,
	@OL_PR_ID_5			bigint,
	@OL_PR_QTY_5		int)
AS
BEGIN
    DECLARE @Order_Id           bigint,
            @TotalPrice         decimal(12,2) = 0,
			@NullDate			datetime = '1900-01-01',
			@SeqNumber			tinyint = 0,
			@SeqCount			tinyint = 5,
			@SeqID				tinyint,
			@PR_ID				bigint,
			@PR_Qty				int,
            @PR_Price           numeric(9,2),
            @InsertFlag         bit = 0

    --insert an Order record to claim the O_ID
    INSERT INTO dbo.Orders (O_C_ID, O_TOTAL, O_DTS, O_FM_DTS) VALUES (@C_ID, 0, GETDATE(), @NullDate)

    -- get the inserted order id
    SELECT  @order_id   = SCOPE_IDENTITY()

    -- now process the order lines
	WHILE (@SeqNumber < @SeqCount)
	BEGIN
		SELECT	@SeqNumber	= @SeqNumber + 1

		IF @SeqNumber = 1
		BEGIN
			SELECT	@SeqID	    = @OL_SEQ_1,
					@PR_ID	    = @OL_PR_ID_1,
					@PR_Qty	    = @OL_PR_QTY_1,
                    @PR_Price   = PR_PRICE
            FROM    dbo.Products
            WHERE   PR_ID       = @OL_PR_ID_1

            IF @@ROWCOUNT > 0
            BEGIN
                SET     @InsertFlag = 1
                SET     @TotalPrice = @TotalPrice + (@PR_QTY * @PR_Price)
            END
        END

		IF @SeqNumber = 2
		BEGIN
			SELECT	@SeqID	= @OL_SEQ_2,
					@PR_ID	= @OL_PR_ID_2,
					@PR_Qty	= @OL_PR_QTY_2,
                    @PR_Price   = PR_PRICE
            FROM    dbo.Products
            WHERE   PR_ID       = @OL_PR_ID_2

            IF @@ROWCOUNT > 0
            BEGIN
                SET     @InsertFlag = 1
                SET     @TotalPrice = @TotalPrice + (@PR_QTY * @PR_Price)
            END
        END

		IF @SeqNumber = 3
		BEGIN
			SELECT	@SeqID	= @OL_SEQ_3,
					@PR_ID	= @OL_PR_ID_3,
					@PR_Qty	= @OL_PR_QTY_3,
                    @PR_Price   = PR_PRICE
            FROM    dbo.Products
            WHERE   PR_ID       = @OL_PR_ID_3

            IF @@ROWCOUNT > 0
            BEGIN
                SET     @InsertFlag = 1
                SET     @TotalPrice = @TotalPrice + (@PR_QTY * @PR_Price)
            END
        END

		IF @SeqNumber = 4
		BEGIN
			SELECT	@SeqID	= @OL_SEQ_4,
					@PR_ID	= @OL_PR_ID_4,
					@PR_Qty	= @OL_PR_QTY_4,
                    @PR_Price   = PR_PRICE
            FROM    dbo.Products
            WHERE   PR_ID       = @OL_PR_ID_4

            IF @@ROWCOUNT > 0
            BEGIN
                SET     @InsertFlag = 1
                SET     @TotalPrice = @TotalPrice + (@PR_QTY * @PR_Price)
            END
        END

		IF @SeqNumber = 5
		BEGIN
			SELECT	@SeqID	= @OL_SEQ_5,
					@PR_ID	= @OL_PR_ID_5,
					@PR_Qty	= @OL_PR_QTY_5,
                    @PR_Price   = PR_PRICE
            FROM    dbo.Products
            WHERE   PR_ID       = @OL_PR_ID_5

            IF @@ROWCOUNT > 0
            BEGIN
                SET     @InsertFlag = 1
                SET     @TotalPrice = @TotalPrice + (@PR_QTY * @PR_Price)
            END
        END
	
		IF (@InsertFlag = 1)
        BEGIN
			INSERT INTO dbo.OrderLines VALUES (@order_id, @SeqID, @PR_ID, @PR_QTY, @PR_Price, GETDATE())
            SET     @InsertFlag = 0
        END
	END

    -- now update the order with the total price
    UPDATE  dbo.Orders
    SET     O_TOTAL = @TotalPrice
	WHERE   O_ID    = @Order_id AND
			O_C_ID  = @C_ID

   SELECT  @order_id,
           @C_ID,
           @TotalPrice

END
GO



IF EXISTS ( SELECT name FROM sysobjects WHERE name = 'usp_ProductSelectionCriteria' )
    DROP PROCEDURE usp_ProductSelectionCriteria
GO

CREATE PROCEDURE [dbo].usp_ProductSelectionCriteria
(	@LOWER_PR_ID        bigint,
	@UPPER_PR_ID		bigint,
	@PC_ID              bigint)
AS
BEGIN
	DECLARE	@pc_dec001	float,
			@pc_dec002	float,
			@pc_dec003	float,
			@pc_dec004	float,
			@pc_dec005	float,
			@pc_dec006	float,
			@pc_dec007	float,
			@pc_dec008	float,
			@pc_dec009	float,
			@pc_dec010	float,
			@pc_dec011	float,
			@pc_dec012	float,
			@pc_dec013	float,
			@pc_dec014	float,
			@pc_dec015	float,
			@pc_dec016	float,
			@pc_dec017	float,
			@pc_dec018	float,
			@pc_dec019	float,
			@pc_dec020	float,
			@pc_dec021	float,
			@pc_dec022	float,
			@pc_dec023	float,
			@pc_dec024	float,
			@pc_dec025	float,
			@pc_dec026	float,
			@pc_dec027	float,
			@pc_dec028	float,
			@pc_dec029	float,
			@pc_dec030	float,
			@pc_dec031	float,
			@pc_dec032	float,
			@pc_dec033	float,
			@pc_dec034	float,
			@pc_dec035	float,
			@pc_dec036	float,
			@pc_dec037	float,
			@pc_dec038	float,
			@pc_dec039	float,
			@pc_dec040	float,
			@pc_dec041	float,
			@pc_dec042	float,
			@pc_dec043	float,
			@pc_dec044	float,
			@pc_dec045	float,
			@pc_dec046	float,
			@pc_dec047	float,
			@pc_dec048	float,
			@pc_dec049	float,
			@pc_dec050	float,
			@pc_dec051	float,
			@pc_dec052	float,
			@pc_dec053	float,
			@pc_dec054	float,
			@pc_dec055	float,
			@pc_dec056	float,
			@pc_dec057	float,
			@pc_dec058	float,
			@pc_dec059	float,
			@pc_dec060	float,
			@pc_dec061	float,
			@pc_dec062	float,
			@pc_dec063	float,
			@pc_dec064	float,
			@pc_dec065	float,
			@pc_dec066	float,
			@pc_dec067	float,
			@pc_dec068	float,
			@pc_dec069	float,
			@pc_dec070	float,
			@pc_dec071	float,
			@pc_dec072	float,
			@pc_dec073	float,
			@pc_dec074	float,
			@pc_dec075	float,
			@pc_dec076	float,
			@pc_dec077	float,
			@pc_dec078	float,
			@pc_dec079	float,
			@pc_dec080	float,
			@pc_dec081	float,
			@pc_dec082	float,
			@pc_dec083	float,
			@pc_dec084	float,
			@pc_dec085	float,
			@pc_dec086	float,
			@pc_dec087	float,
			@pc_dec088	float,
			@pc_dec089	float,
			@pc_dec090	float,
			@pc_dec091	float,
			@pc_dec092	float,
			@pc_dec093	float,
			@pc_dec094	float,
			@pc_dec095	float,
			@pc_dec096	float,
			@pc_dec097	float,
			@pc_dec098	float,
			@pc_dec099	float,
			@pc_dec100	float

	SELECT	@pc_dec001	= PC_DEC1,
			@pc_dec002	= PC_DEC2,
			@pc_dec003	= PC_DEC3,
			@pc_dec004	= PC_DEC4,
			@pc_dec005	= PC_DEC5,
			@pc_dec006	= PC_DEC6,
			@pc_dec007	= PC_DEC7,
			@pc_dec008	= PC_DEC8,
			@pc_dec009	= PC_DEC9,
			@pc_dec010	= PC_DEC10,
			@pc_dec011	= PC_DEC11,
			@pc_dec012	= PC_DEC12,
			@pc_dec013	= PC_DEC13,
			@pc_dec014	= PC_DEC14,
			@pc_dec015	= PC_DEC15,
			@pc_dec016	= PC_DEC16,
			@pc_dec017	= PC_DEC17,
			@pc_dec018	= PC_DEC18,
			@pc_dec019	= PC_DEC19,
			@pc_dec020	= PC_DEC20,
			@pc_dec021	= PC_DEC21,
			@pc_dec022	= PC_DEC22,
			@pc_dec023	= PC_DEC23,
			@pc_dec024	= PC_DEC24,
			@pc_dec025	= PC_DEC25,
			@pc_dec026	= PC_DEC26,
			@pc_dec027	= PC_DEC27,
			@pc_dec028	= PC_DEC28,
			@pc_dec029	= PC_DEC29,
			@pc_dec030	= PC_DEC30,
			@pc_dec031	= PC_DEC31,
			@pc_dec032	= PC_DEC32,
			@pc_dec033	= PC_DEC33,
			@pc_dec034	= PC_DEC34,
			@pc_dec035	= PC_DEC35,
			@pc_dec036	= PC_DEC36,
			@pc_dec037	= PC_DEC37,
			@pc_dec038	= PC_DEC38,
			@pc_dec039	= PC_DEC39,
			@pc_dec040	= PC_DEC40,
			@pc_dec041	= PC_DEC41,
			@pc_dec042	= PC_DEC42,
			@pc_dec043	= PC_DEC43,
			@pc_dec044	= PC_DEC44,
			@pc_dec045	= PC_DEC45,
			@pc_dec046	= PC_DEC46,
			@pc_dec047	= PC_DEC47,
			@pc_dec048	= PC_DEC48,
			@pc_dec049	= PC_DEC49,
			@pc_dec050	= PC_DEC50,
			@pc_dec051	= PC_DEC51,
			@pc_dec052	= PC_DEC52,
			@pc_dec053	= PC_DEC53,
			@pc_dec054	= PC_DEC54,
			@pc_dec055	= PC_DEC55,
			@pc_dec056	= PC_DEC56,
			@pc_dec057	= PC_DEC57,
			@pc_dec058	= PC_DEC58,
			@pc_dec059	= PC_DEC59,
			@pc_dec060	= PC_DEC60,
			@pc_dec061	= PC_DEC61,
			@pc_dec062	= PC_DEC62,
			@pc_dec063	= PC_DEC63,
			@pc_dec064	= PC_DEC64,
			@pc_dec065	= PC_DEC65,
			@pc_dec066	= PC_DEC66,
			@pc_dec067	= PC_DEC67,
			@pc_dec068	= PC_DEC68,
			@pc_dec069	= PC_DEC69,
			@pc_dec070	= PC_DEC70,
			@pc_dec071	= PC_DEC71,
			@pc_dec072	= PC_DEC72,
			@pc_dec073	= PC_DEC73,
			@pc_dec074	= PC_DEC74,
			@pc_dec075	= PC_DEC75,
			@pc_dec076	= PC_DEC76,
			@pc_dec077	= PC_DEC77,
			@pc_dec078	= PC_DEC78,
			@pc_dec079	= PC_DEC79,
			@pc_dec080	= PC_DEC80,
			@pc_dec081	= PC_DEC81,
			@pc_dec082	= PC_DEC82,
			@pc_dec083	= PC_DEC83,
			@pc_dec084	= PC_DEC84,
			@pc_dec085	= PC_DEC85,
			@pc_dec086	= PC_DEC86,
			@pc_dec087	= PC_DEC87,
			@pc_dec088	= PC_DEC88,
			@pc_dec089	= PC_DEC89,
			@pc_dec090	= PC_DEC90,
			@pc_dec091	= PC_DEC91,
			@pc_dec092	= PC_DEC92,
			@pc_dec093	= PC_DEC93,
			@pc_dec094	= PC_DEC94,
			@pc_dec095	= PC_DEC95,
			@pc_dec096	= PC_DEC96,
			@pc_dec097	= PC_DEC97,
			@pc_dec098	= PC_DEC98,
			@pc_dec099	= PC_DEC99,
			@pc_dec100	= PC_DEC100
	FROM	dbo.Purchase_Criteria
	WHERE	PC_ID	= @PC_ID

	SELECT	TOP 20 PR_NAME,
			((@pc_dec001/PR_DEC1-1)+(@pc_dec002/PR_DEC2-1)+(@pc_dec003/PR_DEC3-1)+(@pc_dec004/PR_DEC4-1)+(@pc_dec005/PR_DEC5-1)+(@pc_dec006/PR_DEC6-1)+(@pc_dec007/PR_DEC7-1)+(@pc_dec008/PR_DEC8-1)+(@pc_dec009/PR_DEC9-1)+(@pc_dec010/PR_DEC10-1)+(@pc_dec011/PR_DEC11-1)+(@pc_dec012/PR_DEC12-1)+(@pc_dec013/PR_DEC13-1)+(@pc_dec014/PR_DEC14-1)+(@pc_dec015/PR_DEC15-1)+(@pc_dec016/PR_DEC16-1)+(@pc_dec017/PR_DEC17-1)+(@pc_dec018/PR_DEC18-1)+(@pc_dec019/PR_DEC19-1)+(@pc_dec020/PR_DEC20-1)+(@pc_dec021/PR_DEC21-1)+(@pc_dec022/PR_DEC22-1)+(@pc_dec023/PR_DEC23-1)+(@pc_dec024/PR_DEC24-1)+(@pc_dec025/PR_DEC25-1)+(@pc_dec026/PR_DEC26-1)+(@pc_dec027/PR_DEC27-1)+(@pc_dec028/PR_DEC28-1)+(@pc_dec029/PR_DEC29-1)+(@pc_dec030/PR_DEC30-1)+(@pc_dec031/PR_DEC31-1)+(@pc_dec032/PR_DEC32-1)+(@pc_dec033/PR_DEC33-1)+(@pc_dec034/PR_DEC34-1)+(@pc_dec035/PR_DEC35-1)+(@pc_dec036/PR_DEC36-1)+(@pc_dec037/PR_DEC37-1)+(@pc_dec038/PR_DEC38-1)+(@pc_dec039/PR_DEC39-1)+(@pc_dec040/PR_DEC40-1)+(@pc_dec041/PR_DEC41-1)+(@pc_dec042/PR_DEC42-1)+(@pc_dec043/PR_DEC43-1)+(@pc_dec044/PR_DEC44-1)+(@pc_dec045/PR_DEC45-1)+(@pc_dec046/PR_DEC46-1)+(@pc_dec047/PR_DEC47-1)+(@pc_dec048/PR_DEC48-1)+(@pc_dec049/PR_DEC49-1)+(@pc_dec050/PR_DEC50-1)+(@pc_dec051/PR_DEC51-1)+(@pc_dec052/PR_DEC52-1)+(@pc_dec053/PR_DEC53-1)+(@pc_dec054/PR_DEC54-1)+(@pc_dec055/PR_DEC55-1)+(@pc_dec056/PR_DEC56-1)+(@pc_dec057/PR_DEC57-1)+(@pc_dec058/PR_DEC58-1)+(@pc_dec059/PR_DEC59-1)+(@pc_dec060/PR_DEC60-1)+(@pc_dec061/PR_DEC61-1)+(@pc_dec062/PR_DEC62-1)+(@pc_dec063/PR_DEC63-1)+(@pc_dec064/PR_DEC64-1)+(@pc_dec065/PR_DEC65-1)+(@pc_dec066/PR_DEC66-1)+(@pc_dec067/PR_DEC67-1)+(@pc_dec068/PR_DEC68-1)+(@pc_dec069/PR_DEC69-1)+(@pc_dec070/PR_DEC70-1)+(@pc_dec071/PR_DEC71-1)+(@pc_dec072/PR_DEC72-1)+(@pc_dec073/PR_DEC73-1)+(@pc_dec074/PR_DEC74-1)+(@pc_dec075/PR_DEC75-1)+(@pc_dec076/PR_DEC76-1)+(@pc_dec077/PR_DEC77-1)+(@pc_dec078/PR_DEC78-1)+(@pc_dec079/PR_DEC79-1)+(@pc_dec080/PR_DEC80-1)+(@pc_dec081/PR_DEC81-1)+(@pc_dec082/PR_DEC82-1)+(@pc_dec083/PR_DEC83-1)+(@pc_dec084/PR_DEC84-1)+(@pc_dec085/PR_DEC85-1)+(@pc_dec086/PR_DEC86-1)+(@pc_dec087/PR_DEC87-1)+(@pc_dec088/PR_DEC88-1)+(@pc_dec089/PR_DEC89-1)+(@pc_dec090/PR_DEC90-1)+(@pc_dec091/PR_DEC91-1)+(@pc_dec092/PR_DEC92-1)+(@pc_dec093/PR_DEC93-1)+(@pc_dec094/PR_DEC94-1)+(@pc_dec095/PR_DEC95-1)+(@pc_dec096/PR_DEC96-1)+(@pc_dec097/PR_DEC97-1)+(@pc_dec098/PR_DEC98-1)+(@pc_dec099/PR_DEC99-1)+(@pc_dec100/PR_DEC100-1)) AS Closeness
	FROM	dbo.Products
	WHERE	PR_ID BETWEEN @LOWER_PR_ID AND @UPPER_PR_ID
	ORDER	BY Closeness ASC
	
END
GO

