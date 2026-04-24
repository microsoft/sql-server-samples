CREATE PROCEDURE [DataLoadSimulation].[GetRandomCustomerCategory]
@RandomCustomerCategoryID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random category ID from the customer category table
  for categories other than corporate (we only want the Head Office
  stores to be of type corporate, and that is set in another
  routine).

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myCustomerCategoryID AS INT
  EXEC [DataLoadSimulation].[GetRandomCustomerCategory]
    @RandomCustomerCategoryID = @myCustomerCategoryID OUTPUT
  SELECT @myCustomerCategoryID

*/

  SELECT TOP 1
         @RandomCustomerCategoryID = CustomerCategoryID
    FROM [Sales].[CustomerCategories]
   WHERE CustomerCategoryID > 0
     AND CustomerCategoryName <> 'Corporate'
   ORDER BY NEWID()

  RETURN

END

