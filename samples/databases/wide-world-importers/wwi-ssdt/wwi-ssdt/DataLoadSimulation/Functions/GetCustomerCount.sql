CREATE FUNCTION [DataLoadSimulation].[GetCustomerCount]
(@CustomerName NVARCHAR(50))
RETURNS INT
AS
BEGIN
/*
Notes:
  Returns the number of rows with that customer name.
  This will either be 1 or 0, and is used to validate
  a customer doesn't exist prior to inserting them

Usage:
  DECLARE @CustCount INT = [DataLoadSimulation].[GetCustomerCount] (N'Tailspin Toys (Head Office)')
  SELECT @CustCount
*/

  DECLARE @CustCount INT

  SELECT @CustCount = COUNT(*)
    FROM [Sales].[Customers]
   WHERE [CustomerName] = @CustomerName

  RETURN @CustCount

END

