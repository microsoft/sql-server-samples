CREATE PROCEDURE [DataLoadSimulation].[GetRandomPaymentDays]
@RandomPaymentDays AS INT OUTPUT
AS
BEGIN
/*
Notes:
  Randomly generates a standard number of payment days

Usage:
  DECLARE @myPaymentDays AS INT
  EXEC [DataLoadSimulation].[GetRandomPaymentDays] @RandomPaymentDays = @myPaymentDays OUTPUT
  SELECT @myPaymentDays

*/
  DECLARE @pd AS INT

  SET @pd = CAST((ABS(CHECKSUM(NEWID())) % 8) AS INT)

  -- Note as 30 and 45 are the most common for payment day values,
  -- we want them to come up more often hence we included them
  -- multiple times
  SET @RandomPaymentDays = CASE WHEN @pd = 0 THEN 30
                                WHEN @pd = 1 THEN 45
                                WHEN @pd = 2 THEN 60
                                WHEN @pd = 3 THEN 90
                                WHEN @pd = 4 THEN 180
                                WHEN @pd = 5 THEN 30
                                WHEN @pd = 6 THEN 45
                                WHEN @pd = 7 THEN 30
                                WHEN @pd = 8 THEN 45
                                ELSE 30
                            END
END

