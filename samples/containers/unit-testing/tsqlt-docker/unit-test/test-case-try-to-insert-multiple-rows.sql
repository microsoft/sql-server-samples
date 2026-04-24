-------------------------------------------------------------------------
-- Demo:       SQL Server CI/CD                                         -
--                                                                      -
-- Script:     Test case: try to insert multiple rows                   -
-- Author:     Sergio Govoni                                            -
-- Notes:      --                                                       -
-------------------------------------------------------------------------

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE UnitTestTRProductSafetyStockLevel.[test try to insert multiple rows]
AS
BEGIN
  /*
    Arrange:
    Spy the procedure Production.usp_raiserror_safety_stock_level
  */
  EXEC tSQLt.SpyProcedure 'Production.usp_Raiserror_SafetyStockLevel';

  /*
    Act:
    Try to insert multiple rows
    The first product has a wrong value for SafetyStockLevel column,
    whereas the value in second one is right
  */
  INSERT INTO Production.Product
  (
    [Name]
    ,ProductNumber
    ,MakeFlag
    ,FinishedGoodsFlag
    ,SafetyStockLevel
    ,ReorderPoint
    ,StandardCost
    ,ListPrice
    ,DaysToManufacture
    ,SellStartDate
    ,rowguid
    ,ModifiedDate
  )
  VALUES
  (
    N'Carbon Bar 1'
    ,N'CB-0001'
    ,0
    ,0
    ,9 /* SafetyStockLevel */
    ,750
    ,0.0000
    ,78.0000
    ,0
    ,GETDATE()
    ,NEWID()
    ,GETDATE()
  ),
  (
    N'Carbon Bar 3'
    ,N'CB-0003'
    ,0
    ,0
    ,15 /* SafetyStockLevel */
    ,750
    ,0.0000
    ,78.0000
    ,0
    ,GETDATE()
    ,NEWID()
    ,GETDATE()
  );

  /*
    Assert
  */
  IF NOT EXISTS (SELECT _id_ FROM Production.usp_Raiserror_SafetyStockLevel_SpyProcedureLog)
    EXEC tSQLt.Fail
      @Message0 = 'Production.usp_Raiserror_SafetyStockLevel_SpyProcedureLog is empty! usp_Raiserror_SafetyStockLevel has not been called!';
END;
GO

EXEC tSQLt.Run 'UnitTestTRProductSafetyStockLevel.[test try to insert multiple rows]';
GO
