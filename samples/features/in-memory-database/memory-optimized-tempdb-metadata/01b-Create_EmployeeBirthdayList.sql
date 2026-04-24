USE AdventureWorks
GO

CREATE OR ALTER PROCEDURE usp_EmployeeBirthdayList @month int AS
BEGIN

	IF OBJECT_ID('tempdb..#Birthdays') IS NOT NULL DROP TABLE #Birthdays;

	CREATE TABLE #Birthdays (BusinessEntityID int NOT NULL PRIMARY KEY);

	INSERT #Birthdays (BusinessEntityID)
	SELECT BusinessEntityID
	FROM HumanResources.Employee
	WHERE MONTH(BirthDate) = @month

	SELECT p.FirstName, p.LastName, a.AddressLine1, a.AddressLine2, a.City, sp.StateProvinceCode, a.PostalCode
	FROM #Birthdays b
	INNER JOIN Person.Person p ON b.BusinessEntityID = p.BusinessEntityID
	INNER JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
	INNER JOIN Person.Address a ON bea.AddressID = a.AddressID
	INNER JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
	INNER JOIN Person.AddressType at ON at.AddressTypeID = bea.AddressTypeID
	WHERE at.Name = N'Home'

END;