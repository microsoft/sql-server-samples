-------------------------------------------------------------------------
-- Demo:       SQL Server CI/CD                                         -
--                                                                      -
-- Script:     Create new test class UnitTestTRProductSafetyStockLevel  -
-- Author:     Sergio Govoni                                            -
-- Notes:      --                                                       -
-------------------------------------------------------------------------

USE [AdventureWorks2017];
GO

-- Create new test class
-- The test class collects test cases for this class
EXEC tSQLt.NewTestClass 'UnitTestTRProductSafetyStockLevel';
GO
