CREATE PROCEDURE [DataLoadSimulation].[GetRandomSecondaryAddress]
@randomSecondaryAddress NVARCHAR(20) OUTPUT
AS
BEGIN
/*
Notes:
  This procedure will randomly select a street name from the table
  variable loaded herein.

  While it would be preferable to have implemented this as a function,
  the NEWID mechanism needed to make this work are not allowed within
  a function hence the requirement to implement in a stored procedure.

Usage:
  DECLARE @r AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetRandomSecondaryAddress] @randomSecondaryAddress = @r OUTPUT;
  SELECT @r
*/

  DECLARE @seconaryAddress TABLE (secondAddress NVARCHAR(20))

  -- A high percentage of the time we want the secondary address to be
  -- blank, so we're putting blank entries in the table to give a good
  -- chance of a blank secondary coming up
  INSERT INTO @seconaryAddress
  VALUES ('PO Box ')
       , ('Suite ')
       , ('Office ')
       , ('Mail Stop ')
       , ('Box ')
       , ('Bin ')
       , ('Room ')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       , ('')
       ;

  DECLARE @sa AS NVARCHAR(20)
  SELECT TOP 1 @sa = secondAddress FROM @seconaryAddress ORDER BY NEWID()
  IF LEN(@sa) > 0
    SET @randomSecondaryAddress = @sa + CAST((ABS(CHECKSUM(NEWID())) % 899) AS NVARCHAR)
  ELSE
    SET @randomSecondaryAddress = ''

  RETURN

END;

