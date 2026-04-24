CREATE PROCEDURE [DataLoadSimulation].[GetRandomStockItemToAdjust]
  @QuantityToAdjust    INT
, @StockItemIDToAdjust INT OUTPUT
AS
BEGIN
/*
Notes:
  Selects stock item to adjust ID.

  As with other similar procs, we have to use a proc as opposed
  to a function as random tools such as NEWID and RAND don't work
  in functions

Usage:
  DECLARE @myStockItemIDToAdjust INT
  EXEC [DataLoadSimulation].[GetRandomStockItemToAdjust]
    10, @StockItemIDToAdjust = @myStockItemIDToAdjust OUTPUT
  SELECT @myStockItemIDToAdjust

*/

  SELECT TOP(1)
         @StockItemIDToAdjust = StockItemID
    FROM Warehouse.StockItemHoldings
   WHERE (QuantityOnHand + @QuantityToAdjust) >= 0
   ORDER BY NEWID()

  RETURN

END

