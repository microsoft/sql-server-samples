CREATE PROCEDURE [DataLoadSimulation].[GetBogativePhoneNumber]
(
    @AreaCode NVARCHAR(4)
  , @PhoneNumber AS NVARCHAR(20) OUTPUT
)
AS
BEGIN
/*
Notes:
  Generates a fake phone number based on the area code

Usage:
  DECLARE @myPhoneNumber AS NVARCHAR(20)
  EXEC [DataLoadSimulation].[GetBogativePhoneNumber]
      @AreaCode = '205'
    , @PhoneNumber = @myPhoneNumber OUTPUT
  SELECT @myPhoneNumber

*/

  DECLARE @phoneLast4  AS NVARCHAR(4)

  SET @phoneLast4 = RIGHT('0000' + CAST((ABS(CHECKSUM(NEWID())) % 9999) AS NVARCHAR) , 4)

  SET @PhoneNumber = '(' + @AreaCode + ') 555-' + @phoneLast4

  RETURN

END

