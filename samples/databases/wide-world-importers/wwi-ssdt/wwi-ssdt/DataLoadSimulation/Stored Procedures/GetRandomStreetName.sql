CREATE PROCEDURE [DataLoadSimulation].[GetRandomStreetName]
@randomStreetName NVARCHAR(20) OUTPUT
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
  EXEC [DataLoadSimulation].[GetRandomStreetName] @randomStreetName = @r OUTPUT;
  SELECT @r
*/

  DECLARE @streetName TABLE (street NVARCHAR(20))

  INSERT INTO @streetName
  VALUES ('Elm')
       , ('Maple')
       , ('Oak')
       , ('Sugar')
       , ('Main')
       , ('Pine')
       , ('Spruce')
       , ('Aspen')
       , ('Birch')
       , ('Fir')
       , ('Hickory')
       , ('Walnut')
       , ('Willow')
       , ('Sycamore')
       , ('Tulip')
       , ('Rose')
       , ('Cotton')
       , ('Ash')
       , ('Lily')
       , ('Cherry')
       , ('Violet')
       , ('First')
       , ('Second')
       , ('Third')
       , ('Fourth')
       , ('Fifth')
       , ('Sixth')
       , ('Seventh')
       , ('Eighth')
       , ('Ninth')
       , ('Tenth')
       , ('Eleventh')
       , ('Twelfth')
       , ('Thirteenth')
       , ('Fourteenth')
       , ('Fifteenth')
       , ('Sixteenth')
       , ('Seventeenth')
       , ('Eighteenth')
       , ('Nineteenth')
       , ('Twentieth')
       , ('1st')
       , ('2nd')
       , ('3rd')
       , ('4th')
       , ('5th')
       , ('6th')
       , ('7th')
       , ('8th')
       , ('9th')
       , ('10th')
       , ('11th')
       , ('12th')
       , ('13th')
       , ('14th')
       , ('15th')
       , ('16th')
       , ('17th')
       , ('18th')
       , ('19th')
       , ('20th')
       ;

  SELECT TOP 1 @randomStreetName = street FROM @streetName ORDER BY NEWID()
  RETURN

END;

