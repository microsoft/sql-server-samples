-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.AddCustomers;
GO

CREATE PROCEDURE DataLoadSimulation.AddCustomers
@CurrentDateTime datetime2(7),
@StartingWhen datetime,
@EndOfTime datetime2(7),
@IsSilentMode bit
WITH EXECUTE AS OWNER
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- add a customer one in 15 days average
    DECLARE @NumberOfCustomersToAdd int = (SELECT TOP(1) Quantity
                                              FROM (VALUES (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (0),
                                                           (0), (0), (0), (0), (1)) AS q(Quantity)
                                              ORDER BY NEWID());
    -- Pushed Notifications to calling proc
    --IF @IsSilentMode = 0
    --BEGIN
    --    PRINT N'Adding ' + CAST(@NumberOfCustomersToAdd AS nvarchar(20)) + N' customers for ' + LEFT(CAST(@CurrentDateTime AS NVARCHAR), 10);
    --END;

    DECLARE @Counter INT = 0;
    DECLARE @CityID INT;
    DECLARE @CityName NVARCHAR(max);
    DECLARE @CityStateProvinceID INT;
    DECLARE @CityStateProvinceCode NVARCHAR(5);
    DECLARE @CityStateProvinceName NVARCHAR(50);
    DECLARE @AreaCode INT;
    DECLARE @CustomerCategoryID INT;

    DECLARE @InUseCounter INT = 0;


    DECLARE @CustomerID int;
    DECLARE @PrimaryContactFullName nvarchar(50);
    DECLARE @PrimaryContactPersonID int;
    DECLARE @PrimaryContactFirstName nvarchar(50);
    DECLARE @PrimaryContactLastName AS NVARCHAR(20);
    DECLARE @CustomerName AS NVARCHAR(100);
    DECLARE @DeliveryMethodID int = [DataLoadSimulation].[GetDeliveryMethodID] (N'Delivery Van');
    DECLARE @DeliveryAddressLine1 nvarchar(max);
    DECLARE @DeliveryAddressLine2 nvarchar(max);
    DECLARE @DeliveryPostalCode nvarchar(max);
    DECLARE @PostalAddressLine1 nvarchar(max);
    DECLARE @PostalAddressLine2 nvarchar(max);
    DECLARE @PostalPostalCode nvarchar(max);
    DECLARE @StreetSuffix nvarchar(max);
    DECLARE @CompanySuffix nvarchar(max);
    DECLARE @StorePrefix nvarchar(max);
    DECLARE @CreditLimit int;

    DECLARE @BuyingGroupID INT
    DECLARE @BuyingGroupName NVARCHAR(50)

    DECLARE @BGWebDomain             AS NVARCHAR(256)
    DECLARE @BGEmailDomain           AS NVARCHAR(256)
    DECLARE @PhoneNumber             AS NVARCHAR(20)
    DECLARE @FaxNumber               AS NVARCHAR(20)
    DECLARE @EmailTo                 AS NVARCHAR(75)
    DECLARE @EmailAddress            AS NVARCHAR(256)
    DECLARE @phoneLast4              AS NVARCHAR(4)
    DECLARE @faxLast4                AS NVARCHAR(4)

    WHILE @Counter < @NumberOfCustomersToAdd
    BEGIN
      EXEC [DataLoadSimulation].[GetFicticiousName]
          @FirstName = @PrimaryContactFirstName OUTPUT
        , @LastName  = @PrimaryContactLastName  OUTPUT
        , @FullName  = @PrimaryContactFullName  OUTPUT
        , @Email     = @EmailTo                 OUTPUT

      -- If full name is null it means we've exhausted our list of
      -- available customer names, so we can no longer add customers
      IF @PrimaryContactFullName IS NULL
        RETURN

      EXEC [DataLoadSimulation].[GetRandomBuyingGroupNotInUse]
          @CityID            = @CityID                OUTPUT
        , @CityName          = @CityName              OUTPUT
        , @StateProvinceCode = @CityStateProvinceCode OUTPUT
        , @StateProvinceName = @CityStateProvinceName OUTPUT
        , @AreaCode          = @AreaCode              OUTPUT
        , @BuyingGroupID     = @BuyingGroupID         OUTPUT
        , @BuyingGroupName   = @BuyingGroupName       OUTPUT
        , @WebDomain         = @BGWebDomain           OUTPUT
        , @EmailDomain       = @BGEmailDomain         OUTPUT
        , @CustomerName      = @CustomerName          OUTPUT

      SET @CustomerID = NEXT VALUE FOR Sequences.CustomerID;
      EXEC [DataLoadSimulation].[GetRandomCustomerCategory]
        @RandomCustomerCategoryID = @CustomerCategoryID OUTPUT

      SET @CreditLimit = CEILING(RAND() * 30) * 100 + 1000;

      EXEC [DataLoadSimulation].[GetRandomStreet]
        @randomStreet = @DeliveryAddressLine1  OUTPUT;
      EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
        @randomSecondaryAddress = @DeliveryAddressLine2  OUTPUT

      EXEC [DataLoadSimulation].[GetRandomStreet]
        @randomStreet = @PostalAddressLine1 OUTPUT;
      EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
        @randomSecondaryAddress = @PostalAddressLine2 OUTPUT

      EXEC [DataLoadSimulation].[GetBogativePostalCode]
          @CityID = @CityID
        , @PostalCode = @DeliveryPostalCode OUTPUT
      SET @PostalPostalCode = @DeliveryPostalCode;

      SET @PrimaryContactPersonID = NEXT VALUE FOR Sequences.PersonID;

      SET @EmailAddress = @EmailTo + @BGEmailDomain

      -- Generate random phone numbers
      EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
          @AreaCode = @AreaCode
        , @PhoneNumber = @PhoneNumber OUTPUT

      EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
          @AreaCode = @AreaCode
        , @PhoneNumber = @FaxNumber OUTPUT

      BEGIN TRAN;

      INSERT [Application].People
          (PersonID, FullName, PreferredName, IsPermittedToLogon, LogonName,
           IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee,
           IsSalesperson, UserPreferences, PhoneNumber, FaxNumber,
           EmailAddress, LastEditedBy, ValidFrom, ValidTo)
      VALUES
          (@PrimaryContactPersonID, @PrimaryContactFullName, @PrimaryContactFirstName, 0, N'NO LOGON',
           0, NULL, 0, 0,
           0, NULL, @PhoneNumber, @FaxNumber,
           @EmailAddress, 1, @CurrentDateTime, @EndOfTime);

      INSERT Sales.Customers
          (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
           BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
           DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
           IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber,
           DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
           DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2,
           PostalPostalCode, LastEditedBy, ValidFrom, ValidTo)
       VALUES
          (@CustomerID, @CustomerName, @CustomerID, @CustomerCategoryID,
           @BuyingGroupID, @PrimaryContactPersonID, NULL, @DeliveryMethodID,
           @CityID, @CityID, @CreditLimit, @StartingWhen, 0,
           0, 0, 7, @PhoneNumber, @FaxNumber,
           NULL, NULL, @BGWebDomain, @DeliveryAddressLine1, @DeliveryAddressLine2,
           @DeliveryPostalCode, [DataLoadSimulation].[GetCityLocation] (@CityID),
           @PostalAddressLine1, @PostalAddressLine2,
           @PostalPostalCode, 1, @CurrentDateTime, @EndOfTime);

      COMMIT;

      SET @Counter += 1;
    END;
END;
GO
