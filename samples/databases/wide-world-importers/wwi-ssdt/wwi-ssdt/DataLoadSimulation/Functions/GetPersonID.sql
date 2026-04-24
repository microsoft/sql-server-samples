CREATE FUNCTION [DataLoadSimulation].[GetPersonID]
( @FullName NVARCHAR(50) )
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the person id for the passed in full name

Usage:
  DECLARE @myPersonId INT = [DataLoadSimulation].[GetPersonID] ('Hubert Helms')
  SELECT @myPersonId

*/
  DECLARE @PerId INT

  SELECT TOP 1
         @PerId = PersonID
    FROM [Application].[People]
   WHERE FullName = @FullName
     AND ValidTo = '99991231 23:59:59.9999999'

  RETURN @PerId

END
