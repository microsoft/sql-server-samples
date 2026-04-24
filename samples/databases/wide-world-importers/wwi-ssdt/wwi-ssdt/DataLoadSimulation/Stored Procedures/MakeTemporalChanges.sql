-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.MakeTemporalChanges;
GO

CREATE PROCEDURE DataLoadSimulation.MakeTemporalChanges
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Counter int;
    DECLARE @RowsToModify int;
    DECLARE @StaffMember int = (SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID());

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE [Application].Cities
            SET LatestRecordedPopulation = LatestRecordedPopulation * 1.04,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE CityID = (SELECT TOP(1) CityID FROM [Application].Cities ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE [Application].StateProvinces
            SET LatestRecordedPopulation = LatestRecordedPopulation * 1.04,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE StateProvinceID = (SELECT TOP(1) StateProvinceID FROM [Application].StateProvinces ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE [Application].Countries
            SET LatestRecordedPopulation = LatestRecordedPopulation * 1.04,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE CountryID = (SELECT TOP(1) CountryID FROM [Application].Countries ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    IF CAST(@StartingWhen AS date) = '20210101'
    BEGIN
        UPDATE [Application].DeliveryMethods
            SET DeliveryMethodName = N'Chilled Van',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE DeliveryMethodName = N'Van with Chiller';
    END;

    IF CAST(@StartingWhen AS date) = '20220101'
    BEGIN
        UPDATE [Application].PaymentMethods
            SET PaymentMethodName = N'Credit-Card',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE PaymentMethodName = N'Credit Card';

        INSERT [Application].TransactionTypes
            (TransactionTypeName, LastEditedBy, ValidFrom, ValidTo)
        VALUES
            (N'Contra', @StaffMember, @StartingWhen, @EndOfTime);

        UPDATE [Application].TransactionTypes
            SET TransactionTypeName = N'Customer Contra',
                LastEditedBy = @StaffMember,
                ValidFrom = DATEADD(minute, 5, @StartingWhen)
            WHERE TransactionTypeName = N'Contra';

        UPDATE Warehouse.Colors
            SET ColorName = N'Steel Gray',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE ColorName = N'Gray';

        INSERT Warehouse.PackageTypes
            (PackageTypeName, LastEditedBy, ValidFrom, ValidTo)
        VALUES
            (N'Bin', @StaffMember, @StartingWhen, @EndOfTime);

        DELETE Warehouse.PackageTypes WHERE PackageTypeName = N'Bin';

        UPDATE Warehouse.StockGroups
            SET StockGroupName = N'Furry Footwear',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE StockGroupName = N'Footwear';
    END;

    IF CAST(@StartingWhen AS date) = '20210101'
    BEGIN
        UPDATE Purchasing.SupplierCategories
            SET SupplierCategoryName = N'Courier Services Supplier',
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE SupplierCategoryName = N'Courier';
    END;

    IF CAST(@StartingWhen AS date) = '20200701'
    BEGIN
        INSERT Sales.CustomerCategories
            (CustomerCategoryName, LastEditedBy, ValidFrom, ValidTo)
        VALUES
            (N'Retailer', 1, @StartingWhen, @EndOfTime);

        UPDATE Sales.CustomerCategories
            SET CustomerCategoryName = N'General Retailer',
                LastEditedBy = @StaffMember,
                ValidFrom = DATEADD(minute, 15, @StartingWhen)
            WHERE CustomerCategoryName = N'Retailer';
    END;

    IF DAY(@StartingWhen) = 1 AND MONTH(@StartingWhen) = 7
    BEGIN
        SET @Counter = 0;
        SET @RowsToModify = CEILING(RAND() * 20);

        WHILE @Counter < @RowsToModify
        BEGIN
            UPDATE Sales.Customers
            SET CreditLimit = CreditLimit * 1.05,
                LastEditedBy = @StaffMember,
                ValidFrom = @StartingWhen
            WHERE CustomerID = (SELECT TOP(1) CustomerID FROM Sales.Customers WHERE CreditLimit > 0 ORDER BY NEWID());
            SET @Counter += 1;
        END;
    END;

    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Modifying a few temporal items for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

END;
GO