CREATE PROCEDURE [DataLoadSimulation].[GetRandomCustomer]
  @RandomCustomerID INT OUTPUT
, @CustomerPrimaryContactPersonID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random sales person ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myCustomerID INT
  DECLARE @myCustomerPrimaryContactPersonID INT
  EXEC [DataLoadSimulation].[GetRandomCustomer]
      @RandomCustomerID = @myCustomerID OUTPUT
    , @CustomerPrimaryContactPersonID = @myCustomerPrimaryContactPersonID OUTPUT
  SELECT @myCustomerID, @myCustomerPrimaryContactPersonID

*/

  SELECT TOP(1)
         @RandomCustomerID = c.CustomerID
       , @CustomerPrimaryContactPersonID = c.PrimaryContactPersonID
    FROM Sales.Customers AS c
   WHERE c.IsOnCreditHold = 0
     AND ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END


