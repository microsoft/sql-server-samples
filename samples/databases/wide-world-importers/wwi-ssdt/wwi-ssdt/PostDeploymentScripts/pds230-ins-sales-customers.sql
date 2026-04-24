PRINT 'Inserting Sales.Customers'
GO

-- BuyingGroupID 1 is for individual buyers and is used
-- in the AddCustomers procedure, this one populates
-- corporate companies
DECLARE buyinggroup CURSOR
  FOR SELECT [BuyingGroupID], [BuyingGroupName]
        FROM [Sales].[BuyingGroups]
       WHERE [ValidTo] = '9999-12-31 23:59:59.9999999'
         AND [BuyingGroupID] > 1

DECLARE @BuyingGroupID       AS INT
DECLARE @BuyingGroupName     AS NVARCHAR(50)
DECLARE @CurrentDateTime     AS DATETIME2(7) = '20200101';
DECLARE @EndOfTime           AS DATETIME2(7) =  '99991231 23:59:59.9999999';
DECLARE @myCityID            AS INT
DECLARE @myCityName          AS NVARCHAR(50)
DECLARE @myStateProvinceCode AS NVARCHAR(5)
DECLARE @myStateProvinceName AS NVARCHAR(50)
DECLARE @myAreaCode          AS NVARCHAR(3)
DECLARE @myFirstName         AS NVARCHAR(20)
DECLARE @myLastName          AS NVARCHAR(20)
DECLARE @myFullName          AS NVARCHAR(40)
DECLARE @myEmail             AS NVARCHAR(200)

-- Variables / Constants for People table
DECLARE @PersonID                AS INT            = 1000
DECLARE @FullName                AS NVARCHAR(50)
DECLARE @PreferredName           AS NVARCHAR(50)
DECLARE @IsPermittedToLogon      AS BIT            = 0
DECLARE @LogonName               AS NVARCHAR(50)   = 'NO LOGON'
DECLARE @IsExternalLogonProvider AS BIT            = 0
DECLARE @HashedPassword          AS VARBINARY(MAX) = NULL
DECLARE @IsSystemUser            AS BIT            = 0
DECLARE @IsEmployee              AS BIT            = 0
DECLARE @IsSalesperson           AS BIT            = 0
DECLARE @UserPreferences         AS NVARCHAR(MAX)  = NULL
DECLARE @PhoneNumber             AS NVARCHAR(20)
DECLARE @FaxNumber               AS NVARCHAR(20)
DECLARE @EmailAddress            AS NVARCHAR(256)
DECLARE @LastEditedBy            AS INT            = 1
DECLARE @personMainContact       AS INT
DECLARE @personSecondaryContact  AS INT
DECLARE @loopCounter             AS INT
DECLARE @myEmailDomain           AS NVARCHAR(256)

-- Variables/Constants for the Customer table
DECLARE @CustomerID                   AS INT = 0
DECLARE @CustomerName                 AS NVARCHAR(100)
DECLARE @BillToCustomerID             AS INT
DECLARE @CustomerCategoryID           AS INT
DECLARE @PrimaryContactPersonID       AS INT
DECLARE @AlternateContactPersonID     AS INT
DECLARE @DeliveryMethodID             AS INT
DECLARE @DeliveryCityID               AS INT
DECLARE @PostalCityID                 AS INT
DECLARE @CreditLimit                  AS DECIMAL(18,2) = NULL
DECLARE @AccountOpenedDate            AS DATE = '20200101'
DECLARE @StandardDiscountPercentage   AS DECIMAL(18,3) = 0
DECLARE @IsStatementSent              AS BIT = 0
DECLARE @IsOnCreditHold               AS BIT = 0
DECLARE @PaymentDays                  AS INT = 7
DECLARE @DeliveryRun                  AS NVARCHAR(5) = ''
DECLARE @RunPosition                  AS NVARCHAR(5) = ''
DECLARE @WebsiteURL                   AS NVARCHAR(256)
DECLARE @DeliveryAddressLine1         AS NVARCHAR(60)
DECLARE @DeliveryAddressLine2         AS NVARCHAR(60)
DECLARE @DeliveryPostalCode           AS NVARCHAR(10)
DECLARE @DeliveryLocation             AS GEOGRAPHY
DECLARE @PostalAddressLine1           AS NVARCHAR(60)
DECLARE @PostalAddressLine2           AS NVARCHAR(60)
DECLARE @PostalPostalCode             AS NVARCHAR(10)

DECLARE @UsedCityIDs                  AS TABLE (UsedCityID INT)
DECLARE @LoopWhileTrue                AS BIT = 1
DECLARE @CityCount                    AS INT = 0
DECLARE @CorporateCustomerCategoryID  AS INT

DECLARE @numberOfRandomCustomers      AS INT
DECLARE @currentRandomCustomerNumber  AS INT

-- Get the highest PERSON ID from the Person table
SELECT @PersonID = MAX(PersonID) FROM [Application].[People]

-- Get the customer category ID for corporate, as all head
-- offices will be of the Corporate customer category type
SELECT @CorporateCustomerCategoryID = CustomerCategoryID
  FROM [Sales].[CustomerCategories]
 WHERE CustomerCategoryName = 'Corporate'

OPEN buyinggroup

FETCH NEXT FROM buyinggroup INTO @BuyingGroupID, @BuyingGroupName
WHILE (@@FETCH_STATUS <> -1)
BEGIN
  -- Get a buying group to insert data for
  SELECT @BuyingGroupID, @BuyingGroupName

  -- Get a random city for the customer and home office
  EXEC [DataLoadSimulation].[GetRandomCity]
    @CityID            = @myCityID            OUTPUT
  , @CityName          = @myCityName          OUTPUT
  , @StateProvinceCode = @myStateProvinceCode OUTPUT
  , @StateProvinceName = @myStateProvinceName OUTPUT
  , @AreaCode          = @myAreaCode          OUTPUT

  -- Get the website URL for the buying group
  EXEC [DataLoadSimulation].[GetBuyingGroupDomain]
      @BuyingGroup = @BuyingGroupName
    , @WebDomain   = @WebsiteURL OUTPUT
    , @EmailDomain = @myEmailDomain OUTPUT

  -- Get payment days for this customer, we will use it for
  -- both the home office and sub offices
  EXEC [DataLoadSimulation].[GetRandomPaymentDays]
    @RandomPaymentDays = @PaymentDays OUTPUT

  -- We will need the IDs of the person for inserting into
  -- the new customer record, so grab them now
  SET @personMainContact = @PersonID + 1
  SET @personSecondaryContact = @PersonID + 2

  -- Loop to insert the two contacts
  SET @loopCounter = 0
  WHILE @loopCounter < 2
  BEGIN
    -- Get a random ficticious person for the first buyer
    EXEC [DataLoadSimulation].[GetFicticiousName]
      @FirstName = @myFirstName OUTPUT
    , @LastName  = @myLastName  OUTPUT
    , @FullName  = @myFullName  OUTPUT
    , @Email     = @myEmail     OUTPUT

    -- Insert the buyers for the home office buying group
    SET @PersonID = @PersonID + 1   -- Note we do mean to increment every time
    -- Copy name data from the GetFicticiousName proc
    SET @FullName = @myFullName
    SET @PreferredName = @myFirstName
    SET @EmailAddress = @myEmail + '@' + @myEmailDomain + '.com'

    -- Generate random phone numbers
    EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
        @AreaCode = @myAreaCode
      , @PhoneNumber = @PhoneNumber OUTPUT

    EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
        @AreaCode = @myAreaCode
      , @PhoneNumber = @FaxNumber OUTPUT

    -- Insert the new person
    INSERT [Application].People
      (PersonID, FullName, PreferredName, IsPermittedToLogon, LogonName,
       IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee,
       IsSalesperson, UserPreferences, PhoneNumber, FaxNumber,
       EmailAddress, LastEditedBy, ValidFrom, ValidTo)
    VALUES
      (@PersonID, @FullName, @PreferredName, @IsPermittedToLogon, @LogonName,
       @IsExternalLogonProvider, @HashedPassword, @IsSystemUser, @IsEmployee,
       @IsSalesperson, @UserPreferences, @PhoneNumber, @FaxNumber,
       @EmailAddress, @LastEditedBy, @CurrentDateTime, @EndOfTime)

    SET @loopCounter = @loopCounter + 1
  END -- WHILE @loopCounter < 2

  -- Insert the Home Office customer
  SET @CustomerID = @CustomerID + 1
  SET @CustomerName = @BuyingGroupName + ' (Head Office)'
  SET @BillToCustomerID = @CustomerID -- BillToCustomerID will be the head office
  SET @CustomerCategoryID = 3
  SET @DeliveryCityID = @myCityID
  SET @PostalCityID = @myCityID

  -- Get a random delivery method
  EXEC [DataLoadSimulation].[GetRandomDeliveryMethod]
    @RandomDeliveryMethod = @DeliveryMethodID OUTPUT

  -- Generate random phone numbers
  EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
      @AreaCode = @myAreaCode
    , @PhoneNumber = @PhoneNumber OUTPUT

  EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
      @AreaCode = @myAreaCode
    , @PhoneNumber = @FaxNumber OUTPUT

  -- Get the Delivery Address
  EXEC [DataLoadSimulation].[GetRandomStreet]
    @randomStreet = @DeliveryAddressLine1 OUTPUT;
  EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
    @randomSecondaryAddress = @DeliveryAddressLine2 OUTPUT;

  -- Get the Postal Address
  EXEC [DataLoadSimulation].[GetRandomStreet]
    @randomStreet = @PostalAddressLine1 OUTPUT;
  EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
    @randomSecondaryAddress = @PostalAddressLine2 OUTPUT;

  -- Get the geography for this location
  SET @DeliveryLocation = [DataLoadSimulation].[GetCityLocation] (@myCityID)

  -- Generate some bogative postal codes
  EXEC [DataLoadSimulation].[GetBogativePostalCode]
      @CityID = @myCityID
    , @PostalCode = @DeliveryPostalCode OUTPUT

  EXEC [DataLoadSimulation].[GetBogativePostalCode]
      @CityID = @myCityID
    , @PostalCode = @PostalPostalCode OUTPUT

  SET @CreditLimit = CEILING(RAND() * 30) * 100 + 1000;

  INSERT Sales.Customers
    (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
     BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
     DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
     IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber,
     DeliveryRun, RunPosition, WebsiteURL,
     DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
     PostalAddressLine1, PostalAddressLine2, PostalPostalCode,
     LastEditedBy, ValidFrom, ValidTo)
   VALUES
    (@CustomerID, @CustomerName, @BillToCustomerID, @CorporateCustomerCategoryID,
     @BuyingGroupID, @personMainContact, @personSecondaryContact, @DeliveryMethodID,
     @DeliveryCityID, @PostalCityID, @CreditLimit, @AccountOpenedDate, @StandardDiscountPercentage,
     @IsStatementSent, @IsOnCreditHold, @PaymentDays, @PhoneNumber, @FaxNumber,
     @DeliveryRun, @RunPosition, @WebsiteURL,
     @DeliveryAddressLine1, @DeliveryAddressLine1, @DeliveryPostalCode, @DeliveryLocation,
     @PostalAddressLine1, @PostalAddressLine2, @PostalPostalCode,
     @LastEditedBy, @CurrentDateTime, @EndOfTime);

  -- Begin Inserting a random number of customers for the buying group
  -- Randomly get a number of customers between 3 and 200
  SET @numberOfRandomCustomers = (ABS(CHECKSUM(NEWID())) % 197 ) + 3
  SET @currentRandomCustomerNumber = 2

  -- Reset for this round
  DELETE FROM @UsedCityIDs
  WHILE @currentRandomCustomerNumber <= @numberOfRandomCustomers
  BEGIN
    -- Get a random city for the customer and sub office making
    -- sure we only use a city once
    SET @LoopWhileTrue = 1
    SET @CityCount = 0
    WHILE @LoopWhileTrue = 1
    BEGIN
      EXEC [DataLoadSimulation].[GetRandomCity]
        @CityID            = @myCityID            OUTPUT
      , @CityName          = @myCityName          OUTPUT
      , @StateProvinceCode = @myStateProvinceCode OUTPUT
      , @StateProvinceName = @myStateProvinceName OUTPUT
      , @AreaCode          = @myAreaCode          OUTPUT

      SELECT @CityCount = COUNT(*)
        FROM @UsedCityIDs
       WHERE UsedCityID = @myCityID

      IF (@CityCount = 0)
      BEGIN
        INSERT @UsedCityIDs (UsedCityID) VALUES (@myCityID)
        SET @LoopWhileTrue = 0
      END

    END -- WHILE @LoopWhileTrue = 1

    --   Insert a contact person

    -- Get a random ficticious person for the sub office buyer
    EXEC [DataLoadSimulation].[GetFicticiousName]
      @FirstName = @myFirstName OUTPUT
    , @LastName  = @myLastName  OUTPUT
    , @FullName  = @myFullName  OUTPUT
    , @Email     = @myEmail     OUTPUT

    -- Insert the buyer for the sub office buying group
    SET @PersonID = @PersonID + 1   -- Note we do mean to increment every time
    -- Copy name data from the GetFicticiousName proc
    SET @FullName = @myFullName
    SET @PreferredName = @myFirstName
    SET @EmailAddress = @myEmail + '@' + @myEmailDomain + '.com'

    -- Generate random phone numbers
    EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
        @AreaCode = @myAreaCode
      , @PhoneNumber = @PhoneNumber OUTPUT

    EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
        @AreaCode = @myAreaCode
      , @PhoneNumber = @FaxNumber OUTPUT

    -- Insert the new person
    INSERT [Application].People
      (PersonID, FullName, PreferredName, IsPermittedToLogon, LogonName,
       IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee,
       IsSalesperson, UserPreferences, PhoneNumber, FaxNumber,
       EmailAddress, LastEditedBy, ValidFrom, ValidTo)
    VALUES
      (@PersonID, @FullName, @PreferredName, @IsPermittedToLogon, @LogonName,
       @IsExternalLogonProvider, @HashedPassword, @IsSystemUser, @IsEmployee,
       @IsSalesperson, @UserPreferences, @PhoneNumber, @FaxNumber,
       @EmailAddress, @LastEditedBy, @CurrentDateTime, @EndOfTime)

    -- The secondary contact for the suboffices is the primary for the main office
    SET @personSecondaryContact = @personMainContact

    -- Insert the Sub Office customer
    SET @CustomerID = @CustomerID + 1
    SET @CustomerName = @BuyingGroupName + ' (' + @myCityName + ', ' + @myStateProvinceCode + ')'
    SET @DeliveryCityID = @myCityID
    SET @PostalCityID = @myCityID

    -- Get a random delivery method
    EXEC [DataLoadSimulation].[GetRandomDeliveryMethod]
      @RandomDeliveryMethod = @DeliveryMethodID OUTPUT

    -- Generate random phone numbers
    EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
        @AreaCode = @myAreaCode
      , @PhoneNumber = @PhoneNumber OUTPUT

    EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
        @AreaCode = @myAreaCode
      , @PhoneNumber = @FaxNumber OUTPUT

    -- Get the Delivery Address
    EXEC [DataLoadSimulation].[GetRandomStreet]
      @randomStreet = @DeliveryAddressLine1 OUTPUT;
    EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
      @randomSecondaryAddress = @DeliveryAddressLine2 OUTPUT;

    -- Get the Postal Address
    EXEC [DataLoadSimulation].[GetRandomStreet]
      @randomStreet = @PostalAddressLine1 OUTPUT;
    EXEC [DataLoadSimulation].[GetRandomSecondaryAddress]
      @randomSecondaryAddress = @PostalAddressLine2 OUTPUT;

    -- Get the geography for this location
    SET @DeliveryLocation = [DataLoadSimulation].[GetCityLocation] (@myCityID)

    -- Generate some bogative postal codes
    EXEC [DataLoadSimulation].[GetBogativePostalCode]
        @CityID = @myCityID
      , @PostalCode = @DeliveryPostalCode OUTPUT

    EXEC [DataLoadSimulation].[GetBogativePostalCode]
        @CityID = @myCityID
      , @PostalCode = @PostalPostalCode OUTPUT

    -- Get a random customer category for this sub office
    EXEC [DataLoadSimulation].[GetRandomCustomerCategory]
      @RandomCustomerCategoryID = @CustomerCategoryID OUTPUT

    SET @CreditLimit = CEILING(RAND() * 30) * 100 + 1000;

    INSERT Sales.Customers
      (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
       BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
       DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage,
       IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber,
       DeliveryRun, RunPosition, WebsiteURL,
       DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
       PostalAddressLine1, PostalAddressLine2, PostalPostalCode,
       LastEditedBy, ValidFrom, ValidTo)
    VALUES
      (@CustomerID, @CustomerName, @BillToCustomerID, @CustomerCategoryID,
       @BuyingGroupID, @PersonID, @personSecondaryContact, @DeliveryMethodID,
       @DeliveryCityID, @PostalCityID, @CreditLimit, @AccountOpenedDate, @StandardDiscountPercentage,
       @IsStatementSent, @IsOnCreditHold, @PaymentDays, @PhoneNumber, @FaxNumber,
       @DeliveryRun, @RunPosition, @WebsiteURL,
       @DeliveryAddressLine1, @DeliveryAddressLine1, @DeliveryPostalCode, @DeliveryLocation,
       @PostalAddressLine1, @PostalAddressLine2, @PostalPostalCode,
       @LastEditedBy, @CurrentDateTime, @EndOfTime)

    SET @currentRandomCustomerNumber = @currentRandomCustomerNumber + 1
  END -- Move to next site

  -- Move to next buying group
  FETCH NEXT FROM buyinggroup INTO @BuyingGroupID, @BuyingGroupName

END

CLOSE buyinggroup
DEALLOCATE buyinggroup

