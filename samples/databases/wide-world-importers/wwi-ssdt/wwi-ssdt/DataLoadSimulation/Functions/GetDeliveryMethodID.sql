CREATE FUNCTION [DataLoadSimulation].[GetDeliveryMethodID]
( @DeliveryMethodName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the delivery method id for the passed in name

Usage:
  DECLARE @myDeliveryMethodId INT = [DataLoadSimulation].[GetDeliveryMethodID] ('Road Freight')
  SELECT @myDeliveryMethodId

*/
  DECLARE @DelivMethodId INT

  SELECT TOP 1
         @DelivMethodId = DeliveryMethodID
    FROM [Application].DeliveryMethods
   WHERE DeliveryMethodName = @DeliveryMethodName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @DelivMethodId

END
