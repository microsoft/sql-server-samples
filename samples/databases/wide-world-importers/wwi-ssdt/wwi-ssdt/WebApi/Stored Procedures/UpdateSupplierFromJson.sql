CREATE PROCEDURE [WebApi].[UpdateSupplierFromJson](@Supplier NVARCHAR(MAX), @SupplierID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Purchasing.Suppliers SET
		SupplierName = ISNULL(json.SupplierName, Purchasing.Suppliers.SupplierName),
		SupplierCategoryID = ISNULL(json.SupplierCategoryID, Purchasing.Suppliers.SupplierCategoryID),
		PrimaryContactPersonID = ISNULL(json.PrimaryContactPersonID, Purchasing.Suppliers.PrimaryContactPersonID),
		AlternateContactPersonID = ISNULL(json.AlternateContactPersonID, Purchasing.Suppliers.AlternateContactPersonID),
		DeliveryMethodID = json.DeliveryMethodID,
		DeliveryCityID = ISNULL(json.DeliveryCityID, Purchasing.Suppliers.DeliveryCityID),
		PostalCityID = ISNULL(json.PostalCityID, Purchasing.Suppliers.PostalCityID),
		SupplierReference = json.SupplierReference,
		BankAccountName = ISNULL(json.BankAccountName, Purchasing.Suppliers.BankAccountName),
		BankAccountBranch = ISNULL(json.BankAccountBranch, Purchasing.Suppliers.BankAccountBranch),
		BankAccountCode = ISNULL(json.BankAccountCode, Purchasing.Suppliers.BankAccountCode),
		BankAccountNumber = ISNULL(json.BankAccountNumber, Purchasing.Suppliers.BankAccountNumber),
		BankInternationalCode = json.BankInternationalCode,
		PaymentDays = ISNULL(json.PaymentDays, Purchasing.Suppliers.PaymentDays),
		InternalComments = ISNULL(json.InternalComments, Purchasing.Suppliers.InternalComments),
		PhoneNumber = ISNULL(json.PhoneNumber, Purchasing.Suppliers.PhoneNumber),
		FaxNumber = ISNULL(json.FaxNumber, Purchasing.Suppliers.FaxNumber),
		WebsiteURL = ISNULL(json.WebsiteURL, Purchasing.Suppliers.WebsiteURL),
		DeliveryAddressLine1 = ISNULL(json.DeliveryAddressLine1, Purchasing.Suppliers.DeliveryAddressLine1),
		DeliveryAddressLine2 = ISNULL(json.DeliveryAddressLine2, Purchasing.Suppliers.DeliveryAddressLine2),
		DeliveryPostalCode = ISNULL(json.DeliveryPostalCode, Purchasing.Suppliers.DeliveryPostalCode),
		PostalAddressLine1 = ISNULL(json.PostalAddressLine1, Purchasing.Suppliers.PostalAddressLine1),
		PostalAddressLine2 = ISNULL(json.PostalAddressLine2, Purchasing.Suppliers.PostalAddressLine2),
		PostalPostalCode = ISNULL(json.PostalPostalCode, Purchasing.Suppliers.PostalPostalCode),
		LastEditedBy = @UserID
	FROM OPENJSON (@Supplier)
		WITH (
			SupplierName nvarchar(100),
			SupplierCategoryID int,
			PrimaryContactPersonID int,
			AlternateContactPersonID int,
			DeliveryMethodID int,
			DeliveryCityID int,
			PostalCityID int,
			SupplierReference nvarchar(20),
			BankAccountName nvarchar(50),
			BankAccountBranch nvarchar(50),
			BankAccountCode nvarchar(20),
			BankAccountNumber nvarchar(20),
			BankInternationalCode nvarchar(20),
			PaymentDays int,
			InternalComments nvarchar(MAX),
			PhoneNumber nvarchar(20),
			FaxNumber nvarchar(20),
			WebsiteURL nvarchar(256),
			DeliveryAddressLine1 nvarchar(60),
			DeliveryAddressLine2 nvarchar(60),
			DeliveryPostalCode nvarchar(10),
			PostalAddressLine1 nvarchar(60),
			PostalAddressLine2 nvarchar(60),
			PostalPostalCode nvarchar(10)) as json
	WHERE
		Purchasing.Suppliers.SupplierID = @SupplierID

END