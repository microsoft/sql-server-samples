
CREATE PROCEDURE [DataLoadSimulation].[DailyProcessToCreateHistory]
    @StartDate                           date
  , @EndDate                             date
  , @AverageNumberOfCustomerOrdersPerDay int = 30
  , @SaturdayPercentageOfNormalWorkDay   int
  , @SundayPercentageOfNormalWorkDay     int
  , @UpdateCustomFields                  bit
  , @IsSilentMode                        bit
  , @AreDatesPrinted                     bit
  , @MinYearlyGrowthPercent              int = -5
  , @MaxYearlyGrowthPercent              int = 15
  , @MinSeasonalVariationPercent         int = -10
  , @MaxSeasonalVariationPercent         int = 30
  , @MaxDailyVariationPercent            int = 20

AS
BEGIN
    SET NOCOUNT ON;
	SET XACT_ABORT ON;

    DECLARE @CurrentDateTime        datetime2(7) = @StartDate;
    DECLARE @EndOfTime              datetime2(7) =  '99991231 23:59:59.9999999';
    DECLARE @StartingWhen           datetime;
	DECLARE @OldNumberOfCustomerOrders int;
    DECLARE @NumberOfCustomerOrders int;
    DECLARE @IsWeekday              bit;
    DECLARE @IsSaturday             bit;
    DECLARE @IsSunday               bit;
    DECLARE @IsMonday               bit;
    DECLARE @Weekday                int;
    DECLARE @IsStaffOnly            bit;
    DECLARE @DateMessage            nvarchar(256);
	
	-- verify whether orders exist, and if so, compute the avg number of customer orders in the last year
	IF EXISTS (SELECT 1 FROM Sales.Orders)
	BEGIN
		SELECT @OldNumberOfCustomerOrders=	AVG(t.OrderCount)
		FROM (SELECT COUNT(*) AS OrderCount FROM Sales.Orders
			WHERE DATEPART(year,OrderDate) = DATEPART(year,(SELECT MAX(OrderDate) FROM Sales.Orders))
				AND DATEPART(weekday,OrderDate) NOT IN (1,7)
				AND BackorderOrderID IS NULL
			GROUP BY OrderDate) t
	END
	ELSE
		SET @OldNumberOfCustomerOrders = @AverageNumberOfCustomerOrdersPerDay


	/*


	delete from DataLoadSimulation.SeasonVariation
	DECLARE @MinSeasonalVariationPercent int = 7
	DECLARE @MaxSeasonalVariationPercent int = 25
	DECLARE @MinYearlyGrowthPercent int = 3
	DECLARE @MaxYearlyGrowthPercent int = 30
	declare @StartDate date = '20200101'
	declare @EndDate date = '20230101'
	declare @CurrentDateTime datetime2 = @StartDate
	declare @MaxDailyVariationPercent int = 5

	drop table if exists #result
	create table #result
	(OrderDate date, OrderCount int)*/
	
	-- compute actual seasonal variation
	DECLARE @CurrentYear int = DATEPART(year, @StartDate)
	WHILE @CurrentYear <= DATEPART(year, @EndDate)
	BEGIN
		DECLARE @CurrentSeason smallint = 1
		--compute new yearly variation for each year
		DECLARE @YearlyVariation float = 1 + (@MinYearlyGrowthPercent + RAND() * CAST(@MaxYearlyGrowthPercent - @MinYearlyGrowthPercent AS float))/100;
		WHILE @CurrentSeason <= 4
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM DataLoadSimulation.SeasonVariation WHERE [Year]=@CurrentYear and Season=@CurrentSeason)
			BEGIN
				-- compute seasonal variation
				DECLARE @SeasonalVariation float
				SET @SeasonalVariation = 1 + (@MinSeasonalVariationPercent + RAND() * CAST(@MaxSeasonalVariationPercent - @MinSeasonalVariationPercent AS float))/100
				IF @CurrentSeason % 2 = 1
					SET @SeasonalVariation = 1/@SeasonalVariation

				INSERT DataLoadSimulation.SeasonVariation ([Year], [Season], YearlyVariation, SeasonalVariation)
				VALUES (@CurrentYear, @CurrentSeason, @YearlyVariation, @SeasonalVariation)
			END
			SET @CurrentSeason += 1
		END
		SET @CurrentYear += 1
	END
	--select * from DataLoadSimulation.SeasonVariation


	/*
	DECLARE @OldNumberOfCustomerOrders int = 600;
    DECLARE @NumberOfCustomerOrders int;
	WHILE @CurrentDateTime <= @EndDate
	BEGIN
		SET @CurrentYear = DATEPART(year, @CurrentDateTime)
		SET @CurrentSeason = CEILING(CAST(DATEPART(month, @CurrentDateTime) AS float)/ 3)

		SELECT @SeasonalVariation=SeasonalVariation, @YearlyVariation=YearlyVariation
		FROM DataLoadSimulation.SeasonVariation
		WHERE [Year]=@CurrentYear AND Season=@CurrentSeason

		DECLARE @x float = CAST(DATEDIFF(day, DATEFROMPARTS(@CurrentYear, (@CurrentSeason*3)-2, 1), @CurrentDateTime) AS FLOAT)/90
		IF @x > 1
			SET @x = 1;

		--compute location on seasonal bell curve
		DECLARE @SeasonEffect float = (SIN(2 * 3.1415926 * (@x-0.25)) + 1) / 2;

		SET @SeasonEffect = ((@SeasonalVariation - 1) * @SeasonEffect) + 1

		-- compute effect of yearly growth on day at hand
		DECLARE @YearlyEffect float = 1+CAST((@YearlyVariation-1) AS float)*(CAST((DATEDIFF(day, DATEFROMPARTS(@CurrentYear-1, 12, 31), @CurrentDateTime)) AS float)/183)

		DECLARE @DailyEffect float = RAND()
		IF @DailyEffect < 0.5
			SET @DailyEffect = 0-@DailyEffect
			
		SET @DailyEffect = 1 + @DailyEffect * (CAST(@MaxDailyVariationPercent AS float)/100)

		SET @NumberOfCustomerOrders = @OldNumberOfCustomerOrders * @DailyEffect * @SeasonEffect * @YearlyEffect

		--INSERT #result select @CurrentDateTime, @NumberOfCustomerOrders
		
		SET @CurrentDateTime = DATEADD(day, 1, @CurrentDateTime);

		--when rolling over to new year, take the old order count as baseline
		IF DATEPART(day, @CurrentDateTime)=1 AND DATEPART(month, @CurrentDateTime)=1
			SET @OldNumberOfCustomerOrders=@OldNumberOfCustomerOrders* @YearlyEffect
	END*/
	--select * from #result


    SET DATEFIRST 7;  -- Week begins on Sunday

    EXEC DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad;

	BEGIN TRY

		WHILE @CurrentDateTime <= @EndDate
		BEGIN
			-- one transaction per day
			BEGIN TRAN
			SET @DateMessage = N'Processing '
							 + SUBSTRING(DATENAME(weekday, @CurrentDateTime), 1,3)
							 + N' '
							 + CONVERT(nvarchar(20), @CurrentDateTime, 107)
							 + N' '
							 + CAST(DATEDIFF(DAY, @CurrentDateTime, @EndDate) AS NVARCHAR)
							 + N' Days Remaining '
							 ;



			IF @AreDatesPrinted <> 0 OR @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage
			END;


		-- compute number of orders to process
			SET @CurrentYear = DATEPART(year, @CurrentDateTime)
			SET @CurrentSeason = CEILING(CAST(DATEPART(month, @CurrentDateTime) AS float)/ 3)

			SELECT @SeasonalVariation=SeasonalVariation, @YearlyVariation=YearlyVariation
			FROM DataLoadSimulation.SeasonVariation
			WHERE [Year]=@CurrentYear AND Season=@CurrentSeason

			DECLARE @x float = CAST(DATEDIFF(day, DATEFROMPARTS(@CurrentYear, (@CurrentSeason*3)-2, 1), @CurrentDateTime) AS FLOAT)/90
			IF @x > 1
				SET @x = 1;

			--compute location on seasonal bell curve
			DECLARE @SeasonEffect float = (SIN(2 * 3.1415926 * (@x-0.25)) + 1) / 2;

			SET @SeasonEffect = ((@SeasonalVariation - 1) * @SeasonEffect) + 1

			-- compute effect of yearly growth on day at hand
			DECLARE @YearlyEffect float = 1+CAST((@YearlyVariation-1) AS float)*(CAST((DATEDIFF(day, DATEFROMPARTS(@CurrentYear-1, 12, 31), @CurrentDateTime)) AS float)/183)

			DECLARE @DailyEffect float = RAND()
			IF @DailyEffect < 0.5
				SET @DailyEffect = 0-@DailyEffect
			
			SET @DailyEffect = 1 + @DailyEffect * (CAST(@MaxDailyVariationPercent AS float)/100)

			SET @NumberOfCustomerOrders = @OldNumberOfCustomerOrders * @DailyEffect * @SeasonEffect * @YearlyEffect

		  -- Calculate the days of the week - different processing happens on each day
			SET @Weekday = DATEPART(weekday, @CurrentDateTime);
			SET @IsSaturday = 0;
			SET @IsSunday = 0;
			SET @IsMonday = 0;
			SET @IsWeekday = 1;

			IF @Weekday = 7
			BEGIN
				SET @IsSaturday = 1;
				SET @IsWeekday = 0;
			END;
			IF @Weekday = 1
			BEGIN
				SET @IsSunday = 1;
				SET @IsWeekday = 0;
			END;
			IF @Weekday = 2 SET @IsMonday = 1;

		-- Purchase orders
			IF @IsWeekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Receiving Purchase Orders'
				END;

				-- Start receiving purchase orders at 7AM on weekdays
				SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
				EXEC DataLoadSimulation.ReceivePurchaseOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Password changes
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Receiving Changing Passwords'
			END;
			SET @StartingWhen = DATEADD(hour, 8, @CurrentDateTime);
			EXEC DataLoadSimulation.ChangePasswords @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Activate new website users
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Activating Website Logins'
			END;
			SET @StartingWhen = DATEADD(minute, 10, DATEADD(hour, 8, @CurrentDateTime));
			EXEC DataLoadSimulation.ActivateWebsiteLogons @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Payments to suppliers
			IF DATEPART(weekday, @CurrentDateTime) = 2
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Paying Suppliers'
				END;
				SET @StartingWhen = DATEADD(hour, 9, @CurrentDateTime); -- Suppliers are paid on Monday mornings
				EXEC DataLoadSimulation.PaySuppliers @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Customer orders received
			SET @StartingWhen = DATEADD(hour, 10, @CurrentDateTime);
--			SET @NumberOfCustomerOrders = @AverageNumberOfCustomerOrdersPerDay / 2
--										+ CEILING(RAND() * @AverageNumberOfCustomerOrdersPerDay);
			SET @NumberOfCustomerOrders = CASE DATEPART(weekday, @CurrentDateTime)
											   WHEN 7
											   THEN FLOOR(@NumberOfCustomerOrders * @SaturdayPercentageOfNormalWorkDay / 100)
											   WHEN 1
											   THEN FLOOR(@NumberOfCustomerOrders * @SundayPercentageOfNormalWorkDay / 100)
											   ELSE @NumberOfCustomerOrders
										  END;
/*				SET @NumberOfCustomerOrders = FLOOR(@NumberOfCustomerOrders * CASE WHEN YEAR(@StartingWhen) = 2013 THEN 1.0
																				   WHEN YEAR(@StartingWhen) = 2014 THEN 1.12
																												   WHEN YEAR(@StartingWhen) = 2015 THEN 1.21
																												   WHEN YEAR(@StartingWhen) = 2016 THEN 1.23
																												   ELSE 1.26
																											END
											   );*/
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Creating Customer Orders'
			END;
			EXEC DataLoadSimulation.CreateCustomerOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @NumberOfCustomerOrders, @IsSilentMode;

		-- Pick any customer orders that can be picked
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Picking Stock for Customer Orders'
			END;
			SET @StartingWhen = DATEADD(hour, 11, @CurrentDateTime);
			EXEC DataLoadSimulation.PickStockForCustomerOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Process any payments from customers
			IF @Weekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Process Customer Payments'
				END;
				SET @StartingWhen = DATEADD(minute, 30, DATEADD(hour, 11, @CurrentDateTime));
				EXEC DataLoadSimulation.ProcessCustomerPayments @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Invoice orders that have been fully picked
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Invoice Picked Orders'
			END;
			SET @StartingWhen = DATEADD(hour, 12, @CurrentDateTime);
			EXEC DataLoadSimulation.InvoicePickedOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Place supplier orders
			IF @Weekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Placing Supplier Orders'
				END;
				SET @StartingWhen = DATEADD(hour, 13, @CurrentDateTime);
				EXEC DataLoadSimulation.PlaceSupplierOrders @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- End of quarter stock take
			IF     (MONTH(@CurrentDateTime) =  1 AND DAY(@CurrentDateTime) = 31)
				OR (MONTH(@CurrentDateTime) =  4 AND DAY(@CurrentDateTime) = 30)
				OR (MONTH(@CurrentDateTime) =  7 AND DAY(@CurrentDateTime) = 31)
				OR (MONTH(@CurrentDateTime) = 10 AND DAY(@CurrentDateTime) = 31)
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Performing Stock Take'
				END;
				SET @StartingWhen = DATEADD(hour, 14, @CurrentDateTime);
				EXEC DataLoadSimulation.PerformStocktake @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		-- Record invoice deliveries
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Recording Invoice Deliveries'
			END;
			SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
			EXEC DataLoadSimulation.RecordInvoiceDeliveries @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Add customers
			IF @Weekday <> 0
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Adding Customers'
				END;
				SET @StartingWhen = DATEADD(hour, 15, @CurrentDateTime);
				EXEC DataLoadSimulation.AddCustomers @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;
			END;

		 -- Add stock items
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Adding Stock Items'
			END;
			SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
			EXEC DataLoadSimulation.AddStockItems @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Add special deals
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Adding Special Deals'
			END;
			SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
			EXEC DataLoadSimulation.AddSpecialDeals @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		 -- Temporal changes
			IF @IsSilentMode = 0
			BEGIN
				PRINT @DateMessage + N'- Making Temporal Changes'
			END;
			SET @StartingWhen = DATEADD(hour, 16, @CurrentDateTime);
			EXEC DataLoadSimulation.MakeTemporalChanges @CurrentDateTime, @StartingWhen, @EndOfTime, @IsSilentMode;

		-- Record delivery van temperatures
			IF @CurrentDateTime >= '20220101'
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Recording Delivery Van Temperatures'
				END;
				SET @StartingWhen = DATEADD(hour, 7, @CurrentDateTime);
				EXEC DataLoadSimulation.RecordDeliveryVanTemperatures 300, 2, @CurrentDateTime, @StartingWhen, @IsSilentMode;
			END;

		-- Record cold room temperatures
			IF @CurrentDateTime >= '20211220'
			BEGIN
				IF @IsSilentMode = 0
				BEGIN
					PRINT @DateMessage + N'- Recording Cold Room Temperatures'
				END;
				EXEC DataLoadSimulation.RecordColdRoomTemperatures 3600, 40, @CurrentDateTime, @EndOfTime, @IsSilentMode;
			END;

			IF @IsSilentMode = 0
			BEGIN
				PRINT N' ';
			END;

			SET @CurrentDateTime = DATEADD(day, 1, @CurrentDateTime);
			-- if rolling over the year, re-baseline order count
			IF DATEPART(day, @CurrentDateTime)=1 AND DATEPART(month, @CurrentDateTime)=1
				SET @OldNumberOfCustomerOrders=@OldNumberOfCustomerOrders* @YearlyEffect
			COMMIT
		END; -- of processing each day

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Updating Custom Fields';
		END;
		IF @UpdateCustomFields <> 0
		BEGIN
			EXEC DataLoadSimulation.UpdateCustomFields @EndDate;
		END;

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Reactivating Temporal Tables After Data Load ';
		END;
		EXEC DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad;

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Reseeding All Sequences';
		END;
		EXEC Sequences.ReseedAllSequences;

		-- Ensure RLS is applied
		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Applying Row Level Security';
		END;
		EXEC [Application].Configuration_ApplyRowLevelSecurity

		IF @IsSilentMode = 0
		BEGIN
			PRINT N'Done Creating Wide World Importers Data History';
		END;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
		BEGIN
			ROLLBACK
		END

		PRINT N'Error Detected. Error ' + CAST(ERROR_NUMBER() AS nvarchar) + N': ' + ERROR_MESSAGE();
		PRINT N'Attempting cleanup before throwing.';

		PRINT N'Reactivating Temporal Tables After Data Load ';
		EXEC DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad;

		PRINT N'Reseeding All Sequences';
		EXEC Sequences.ReseedAllSequences;

		PRINT N'Applying Row Level Security';
		EXEC [Application].Configuration_ApplyRowLevelSecurity;
		THROW;
	END CATCH

END;
