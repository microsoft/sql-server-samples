CREATE PROCEDURE [DataLoadSimulation].[GetRandomSalesPersonID]
@RandomSalesPersonID INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random sales person ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @SalesPersonID INT
  EXEC [DataLoadSimulation].[GetRandomSalesPersonID]
    @RandomSalesPersonID = @SalesPersonID OUTPUT
  SELECT @SalesPersonID

*/

  SELECT TOP 1
         @RandomSalesPersonID = PersonID
    FROM [Application].[People]
   WHERE IsSalesperson <> 0
     AND ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END

