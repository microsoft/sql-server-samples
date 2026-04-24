CREATE PROCEDURE [DataLoadSimulation].[GetRandomDeliveryMethod]
@RandomDeliveryMethod INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects a random delivery method.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @DeliveryMethod INT
  EXEC [DataLoadSimulation].[GetRandomDeliveryMethod]
    @RandomDeliveryMethod = @DeliveryMethod OUTPUT
  SELECT @DeliveryMethod

*/
  SELECT TOP (1) @RandomDeliveryMethod = [DeliveryMethodID]
    FROM [Application].[DeliveryMethods]
   WHERE ValidTo = '99991231 23:59:59.9999999'
   ORDER BY NEWID()

  RETURN

END

