CREATE FUNCTION [DataLoadSimulation].[GetStateProvinceID]
( @StateProvinceCode NVARCHAR(5) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the state province id for the passed in state province code

Usage:
  DECLARE @myStateProvinceId INT
  SELECT @myStateProvinceId = [DataLoadSimulation].[GetStateProvinceID] ('AL')

*/
  DECLARE @SPId INT
  SELECT @SPId = StateProvinceID
    FROM [Application].StateProvinces
   WHERE StateProvinceCode = @StateProvinceCode
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @SPId

END
