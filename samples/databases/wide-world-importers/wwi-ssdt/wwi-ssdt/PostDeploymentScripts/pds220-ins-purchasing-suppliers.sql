PRINT 'Inserting Purchasing.Suppliers'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

DECLARE @Bank NVARCHAR(50)

-- City Variables
DECLARE @myCityID            AS INT
DECLARE @myCityName          AS NVARCHAR(50)
DECLARE @myStateProvinceCode AS NVARCHAR(5)
DECLARE @myStateProvinceName AS NVARCHAR(50)
DECLARE @myAreaCode          AS NVARCHAR(3)

/* A Datum Corporation ----------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 1, 'A Datum Corporation'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Novelty Goods Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Reio Kabin')
  , [DataLoadSimulation].[GetPersonID] ('Oliver Kivi')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Road Freight')
  , @myCityID, @myCityID
  , 'AA20384'
  , 'A Datum Corporation', @Bank, '356981', '8575824136', '25986'
  , 14, NULL
  , '(' + @myAreaCode + ') 555-0100', '(' + @myAreaCode + ') 555-0101'
  , 'http://www.adatum.com'
  , 'Suite 10','183838 Southwest Boulevard','46077',NULL
  , 'PO Box 1039', 'Surrey', '46077'
  , 1, @CurrentDateTime, @EndOfTime)

/* Contoso, Ltd. ----------------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 2, 'Contoso, Ltd.'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Novelty Goods Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Hanna Mihhailov')
  , [DataLoadSimulation].[GetPersonID] ('Paulus Lippmaa')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Refrigerated Road Freight')
  , @myCityID, @myCityID
  , 'B2084020'
  , 'Contoso Ltd', @Bank, '358698', '4587965215', '25868'
  , 7, NULL
  , '(' + @myAreaCode + ') 555-0100', '(' + @myAreaCode + ') 555-0101'
  , 'http://www.contoso.com'
  , 'Unit 2', '2934 Night Road','98253',NULL
  , 'PO Box 1012', 'Jolimont', '98253'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Consolidated Messenger -------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
 ( 3, 'Consolidated Messenger'
 , [DataLoadSimulation].[GetSupplierCategoryID] ('Courier')
 , [DataLoadSimulation].[GetPersonID] ('Kerstin Parn')
 , [DataLoadSimulation].[GetPersonID] ('Helen Ahven')
 , [DataLoadSimulation].[GetDeliveryMethodID] ('NULL')
 , @myCityID, @myCityID
 , '209340283'
 , 'Consolidated Messenger', @Bank, '354269','3254872158','45698'
 , 30, NULL
 , '(' + @myAreaCode + ') 555-0100','(' + @myAreaCode + ') 555-0101'
 ,'http://www.consolidatedmessenger.com'
 , '','894 Market Day Street','94101',NULL
 , 'PO Box 1014','West Mont','94101'
 , 1, @CurrentDateTime, @EndOfTime
 )

/* Fabrikam, Inc. ---------------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 4, 'Fabrikam, Inc.'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Clothing Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Bill Lawson')
  , [DataLoadSimulation].[GetPersonID] ('Helen Moore')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Road Freight')
  , @myCityID, @myCityID
  , '293092'
  , 'Fabrikam Inc', @Bank, '789568', '4125863879', '12546'
  , 30, NULL
  , '(' + @myAreaCode + ') 555-0104', '(' + @myAreaCode + ') 555-0108'
  , 'http://www.fabrikam.com'
  , 'Level 2', '393999 Woodberg Road', '40351', NULL
  , 'PO Box 301', 'Eaglemont', '40351'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Graphic Design Institute -----------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 5, 'Graphic Design Institute'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Novelty Goods Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Penny Buck')
  , [DataLoadSimulation].[GetPersonID] ('Donna Smith')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Refrigerated Air Freight')
  , @myCityID, @myCityID
  , '08803922'
  , 'Graphic Design Institute', @Bank, '563215', '1025869354', '32587'
  , 14, NULL
  , '(' + @myAreaCode + ') 555-0105', '(' + @myAreaCode + ') 555-0106'
  , 'http://www.graphicdesigninstitute.com'
  , '', '45th Street', '64847', NULL
  , 'PO Box 393', 'Willow', '64847'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Humongous Insurance ----------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 6, 'Humongous Insurance'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Insurance Services Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Madelaine  Cartier')
  , [DataLoadSimulation].[GetPersonID] ('Annette Talon')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('NULL')
  , @myCityID, @myCityID
  , '082420938'
  , 'Humongous Insurance', @Bank, '325001', '2569874521', '32569'
  , 14, NULL
  , '(' + @myAreaCode + ') 555-0105', '(' + @myAreaCode + ') 555-0100'
  , 'http://www.humongousinsurance.com'
  , '', '9893 Mount Norris Road', '37770', NULL
  , 'PO Box 94829', 'Boxville', '37770'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Litware, Inc. ----------------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 7, 'Litware, Inc.'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Packaging Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Elias Myllari')
  , [DataLoadSimulation].[GetPersonID] ('Vilma Niva')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Courier')
  , @myCityID, @myCityID
  , 'BC0280982'
  , 'Litware Inc', @Bank, '358769', '3256896325', '21445'
  , 30, NULL
  , '(' + @myAreaCode + ') 555-0108', '(' + @myAreaCode + ') 555-0104'
  , 'http://www.litwareinc.com'
  , 'Level 3', '19 Le Church Street', '95245', NULL
  , 'PO Box 20290', 'Jackson', '95245'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Lucerne Publishing -----------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 8, 'Lucerne Publishing'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Novelty Goods Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Prem Prabhu')
  , [DataLoadSimulation].[GetPersonID] ('Sunita Jadhav')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Refrigerated Air Freight')
  , @myCityID, @myCityID
  , 'JQ082304802'
  , 'Lucerne Publishing', @Bank, '654789', '3254123658', '21569'
  , 30, NULL
  , '(' + @myAreaCode + ') 555-0103', '(' + @myAreaCode + ') 555-0105'
  , 'http://www.lucernepublishing.com'
  , 'Suite 34', '949482 Miller Boulevard', '37659', NULL
  , 'PO Box 8747', 'Westerfold', '37659'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Lucerne Publishing -----------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  ( 9, 'Nod Publishers'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Novelty Goods Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Marcos Costa')
  , [DataLoadSimulation].[GetPersonID] ('Matheus Oliveira')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Refrigerated Air Freight')
  , @myCityID, @myCityID
  , 'GL08029802'
  , 'Nod Publishers', @Bank, '365985', '2021545878', '48758'
  , 7, 'Marcos is not in on Mondays'
  , '(' + @myAreaCode + ') 555-0100', '(' + @myAreaCode + ') 555-0101'
  , 'http://www.nodpublishers.com'
  , 'Level 1', '389 King Street', '27906', NULL
  , 'PO Box 3390', 'Anderson', '27906'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Northwind Electric Cars ------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  (10, 'Northwind Electric Cars'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Toy Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Eliza Soderberg')
  , [DataLoadSimulation].[GetPersonID] ('Sara Karlsson')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Air Freight')
  , @myCityID, @myCityID
  , 'ML0300202'
  , 'Northwind Electric Cars', @Bank, '325447', '3258786987', '36214'
  , 30, NULL
  , '(' + @myAreaCode + ') 555-0105', '(' + @myAreaCode + ') 555-0104'
  , 'http://www.northwindelectriccars.com'
  , '', '440 New Road', '07860', NULL
  , 'PO Box 30920', 'Arlington', '07860'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Trey Research ----------------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  (11, 'Trey Research'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Marketing Services Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Donald Jones')
  , [DataLoadSimulation].[GetPersonID] ('Sharon Graham')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('NULL')
  , @myCityID, @myCityID
  , '082304822'
  , 'Trey Research', @Bank, '658968', '1254785321', '56958'
  , 7, NULL
  , '(' + @myAreaCode + ') 555-0103', '(' + @myAreaCode + ') 555-0101'
  , 'http://www.treyresearch.net'
  , 'Level 43', '9401 Polar Avenue', '57543', NULL
  , 'PO  Box 595', 'Port Fairy', '57543'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* The Phone Company ------------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  (12, 'The Phone Company'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Novelty Goods Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Hai Dam')
  , [DataLoadSimulation].[GetPersonID] ('Thanh Dinh')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('Road Freight')
  , @myCityID, @myCityID
  , '237408032'
  , 'The Phone Company', @Bank, '214568', '7896236589', '25478'
  , 30, NULL
  , '(' + @myAreaCode + ') 555-0105', '(' + @myAreaCode + ') 555-0105'
  , 'http://www.thephone-company.com'
  , 'Level 83', '339 Toorak Road', '56732', NULL
  , 'PO Box 3837', 'Ferny Wood', '56732'
  , 1, @CurrentDateTime, @EndOfTime
  )

/* Woodgrove Bank ---------------------------------------------------------------------*/
EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT

SET @Bank = 'Woodgrove Bank ' + @myCityName

INSERT Purchasing.Suppliers
  ( SupplierID, SupplierName
  , SupplierCategoryID
  , PrimaryContactPersonID
  , AlternateContactPersonID
  , DeliveryMethodID
  , DeliveryCityID, PostalCityID
  , SupplierReference
  , BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode
  , PaymentDays, InternalComments
  , PhoneNumber, FaxNumber
  , WebsiteURL
  , DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation
  , PostalAddressLine1, PostalAddressLine2, PostalPostalCode
  , LastEditedBy, ValidFrom, ValidTo)
VALUES
  (13, 'Woodgrove Bank'
  , [DataLoadSimulation].[GetSupplierCategoryID] ('Financial Services Supplier')
  , [DataLoadSimulation].[GetPersonID] ('Hubert Helms')
  , [DataLoadSimulation].[GetPersonID] ('Donald Small')
  , [DataLoadSimulation].[GetDeliveryMethodID] ('NULL')
  , @myCityID, @myCityID
  , '028034202'
  , 'Woodgrove Bank', @Bank, '325698', '2147825698', '65893'
  , 7, 'Only speak to Donald if Hubert really is not available'
  , '(' + @myAreaCode + ') 555-0103', '(' + @myAreaCode + ') 555-0107'
  , 'http://www.woodgrovebank.com'
  , 'Level 3', '8488 Vienna Boulevard', '94101', NULL
  , 'PO Box 2390', 'Canterbury', '94101'
  , 1, @CurrentDateTime, @EndOfTime
  )


UPDATE s
   SET s.DeliveryLocation = c.[Location]
     , s.[ValidFrom] = DATEADD(minute, CEILING(RAND() * 5), @CurrentDateTime)
  FROM Purchasing.Suppliers AS s
 INNER JOIN [Application].Cities AS c
         ON s.DeliveryCityID = c.CityID
GO

