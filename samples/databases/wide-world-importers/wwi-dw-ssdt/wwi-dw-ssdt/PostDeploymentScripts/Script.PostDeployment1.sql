/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

-- Populate the Date Dimension
DECLARE @YearCounter int = 2013;

WHILE @YearCounter <= 2017
BEGIN
    EXEC Integration.PopulateDateDimensionForYear @YearCounter;
    SET @YearCounter += 1;
END;
GO

SET NOCOUNT ON;

-- Set the last ETL run date for the tables to an initial date.
DECLARE @StartingETLCutoffTime datetime2(7) = '20121231';

MERGE Integration.[ETL Cutoff] AS t
USING (SELECT t.name AS [Table Name]
       FROM sys.tables AS t
       WHERE SCHEMA_NAME(t.schema_id) IN (N'Dimension', N'Fact')) AS s
ON t.[Table Name] = s.[Table Name] COLLATE DATABASE_DEFAULT
WHEN NOT MATCHED
    THEN INSERT ([Table Name], [Cutoff Time])
         VALUES (s.[Table Name], @StartingETLCutoffTime);
GO

-- Create the 'Unknown' rows for each dimension
DECLARE @StartOfTime datetime2(7) = '20130101';
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

IF NOT EXISTS (SELECT 1 FROM Dimension.City WHERE [City Key] = 0)
BEGIN
    INSERT Dimension.City
        ([City Key], [WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
         [Location], [Latest Recorded Population], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A', N'N/A', N'N/A', N'N/A',
         NULL, 0, @StartOfTime, @EndOfTime, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Dimension.Customer WHERE [Customer Key] = 0)
BEGIN
    INSERT Dimension.Customer
        ([Customer Key], [WWI Customer ID], [Customer], [Bill To Customer], Category, [Buying Group],
         [Primary Contact], [Postal Code], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A',
         N'N/A', N'N/A', @StartOfTime, @EndOfTime, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Dimension.Employee WHERE [Employee Key] = 0)
BEGIN
    INSERT Dimension.Employee
        ([Employee Key], [WWI Employee ID], Employee, [Preferred Name],
         [Is Salesperson], Photo, [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A',
         0, NULL, @StartOfTime, @EndOfTime, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Dimension.[Payment Method] WHERE [Payment Method Key] = 0)
BEGIN
    INSERT Dimension.[Payment Method]
        ([Payment Method Key], [WWI Payment Method ID], [Payment Method], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', @StartOfTime, @EndOfTime, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Dimension.[Stock Item] WHERE [Stock Item Key] = 0)
BEGIN
    INSERT Dimension.[Stock Item]
        ([Stock Item Key], [WWI Stock Item ID], [Stock Item], Color, [Selling Package], [Buying Package],
         Brand, Size, [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock],
         Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit],
         Photo, [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A',
         N'N/A', N'N/A', 0, 0, 0,
         N'N/A', 0, 0, 0, 0,
         NULL, @StartOfTime, @EndOfTime, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Dimension.[Supplier] WHERE [Supplier Key] = 0)
BEGIN
    INSERT Dimension.[Supplier]
        ([Supplier Key], [WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
         [Payment Days], [Postal Code], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', N'N/A', N'N/A', N'N/A',
         0, N'N/A', @StartOfTime, @EndOfTime, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Dimension.[Transaction Type] WHERE [Transaction Type Key] = 0)
BEGIN
    INSERT Dimension.[Transaction Type]
        ([Transaction Type Key], [WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To], [Lineage Key])
    VALUES
        (0, 0, N'Unknown', @StartOfTime, @EndOfTime, 0);
END;
GO

-- Configure the sample version
IF NOT EXISTS (SELECT 1 FROM dbo.SampleVersion)
BEGIN
	INSERT dbo.SampleVersion (MajorSampleVersion, MinorSampleVersion, MinSQLServerBuild)
	VALUES (2, 0, N'13.0.4000.0')
END
ELSE
BEGIN
	UPDATE dbo.SampleVersion
	SET MajorSampleVersion=2, MinorSampleVersion=0, MinSQLServerBuild=N'13.0.4000.0'
END
GO
-- Configure DB option that SSDT does not support for Azure SQL DB targets
ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON
GO
-- By default, do not enable PolyBase in the sample. The following can be run afterwards to create PolyBase artifacts in the database.
-- EXEC [Application].Configuration_ApplyPolybase;
-- GO


