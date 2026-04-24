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


/*GRANT VIEW ANY COLUMN ENCRYPTION KEY DEFINITION TO PUBLIC;


GO
GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO PUBLIC;
*/

-- add full-text indexes and use them in the Website.Search* procs, in case full-text indexing is installed
EXEC [Application].Configuration_ApplyFullTextIndexing;
GO

EXEC DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad;
GO

/*
   There are several procs that update the temporal tables.
   Unfortunately these cannot be part of the main build, as SSDT flags them
   as errors. Thus we have to execute the creation of these procs during the
   post deployment process, after the temporal tables are deactivated.
*/
:r "..\DataLoadSimulation\Stored Procedures\UpdateCustomFields.sql"
GO
:r "..\DataLoadSimulation\Stored Procedures\RecordColdRoomTemperatures.sql"
GO
:r "..\DataLoadSimulation\Stored Procedures\MakeTemporalChanges.sql"
GO
:r "..\DataLoadSimulation\Stored Procedures\ChangePasswords.sql"
GO
:r "..\DataLoadSimulation\Stored Procedures\AddStockItems.sql"
GO
:r "..\DataLoadSimulation\Stored Procedures\AddCustomers.sql"
GO
:r "..\DataLoadSimulation\Stored Procedures\ActivateWebsiteLogons.sql"
GO


-- These scripts load the set of starter values needed for the
-- sample database. Due to some restrictions with SSDT, the
-- cities had to be broken down into individual SQL files.
:r .\pds100-ins-app-people.sql
:r .\pds105-ins-dls-ficticiousnamepool.sql
:r .\pds106-ins-dls-areacode.sql
:r .\pds110-ins-app-countries.sql
:r .\pds120-ins-app-deliverymethods.sql
:r .\pds130-ins-app-paymentmethods.sql
:r .\pds140-ins-app-stateprovinces.sql
:r .\pds142-upd-app-stateprovinces-borders.sql

-- This loads a subset of cities
:r .\pds150-ins-app-cities.sql

-- This loads the rest of the cities, however they
-- are optional to load. You can comment these out
-- without negative effects

--:r .\pds150-ins-app-cities-a.sql
--:r .\pds150-ins-app-cities-b.sql
--:r .\pds150-ins-app-cities-c.sql
--:r .\pds150-ins-app-cities-d.sql
--:r .\pds150-ins-app-cities-e.sql
--:r .\pds150-ins-app-cities-f.sql
--:r .\pds150-ins-app-cities-g.sql
--:r .\pds150-ins-app-cities-h.sql
--:r .\pds150-ins-app-cities-i.sql
--:r .\pds150-ins-app-cities-j.sql
--:r .\pds150-ins-app-cities-k.sql
--:r .\pds150-ins-app-cities-l.sql
--:r .\pds150-ins-app-cities-m.sql
--:r .\pds150-ins-app-cities-n.sql
--:r .\pds150-ins-app-cities-o.sql
--:r .\pds150-ins-app-cities-p.sql
--:r .\pds150-ins-app-cities-q.sql
--:r .\pds150-ins-app-cities-r.sql
--:r .\pds150-ins-app-cities-s.sql
--:r .\pds150-ins-app-cities-t.sql
--:r .\pds150-ins-app-cities-u.sql
--:r .\pds150-ins-app-cities-v.sql
--:r .\pds150-ins-app-cities-w.sql
--:r .\pds150-ins-app-cities-x.sql
--:r .\pds150-ins-app-cities-y.sql
--:r .\pds150-ins-app-cities-z.sql


:r .\pds151-ins-post-app-cities.sql
:r .\pds160-ins-app-transactiontypes.sql
:r .\pds170-ins-purchasing-suppliercategories.sql
:r .\pds180-ins-sales-groups-categories.sql
:r .\pds190-ins-warehouse-colors.sql
:r .\pds200-ins-warehouse-packagetypes.sql
:r .\pds210-ins-warehouse-stockgroups.sql
:r .\pds220-ins-purchasing-suppliers.sql
:r .\pds230-ins-sales-customers.sql
:r .\pds240-ins-warehouse-stockitems.sql
:r .\pds250-ins-warehouse-stockitemholdings.sql
:r .\pds260-ins-warehouse-stockitemstockgroups.sql
:r .\pds270-ins-app-systemparameters.sql

PRINT 'Data Load Simulation: Reactivate Temporal Tables after Data Load'
GO
EXEC DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad;
GO

PRINT 'Reseed All Sequences'
GO
EXEC Sequences.ReseedAllSequences;
GO

-- This final set of code populates the database with a limited set of sample data.
-- To obtain the full set of sample data, follow the instructions in the documentation.
PRINT 'Populating limited data set.'
GO

SET NOCOUNT ON;

/* Explanation of parameters
     StartDate: Represents the first date to create data for

     EndDate: The last date to create data for. You can update to the
              current date to get data that was up to date

    AverageNumberOfCustomerOrdersPerDay: For each day the system will generate a
                                         series of orders for customers. This value
                                         indicates how many orders to create. The
                                         higher the value the longer data generation
                                         will take.

    SaturdayPercentageOfNormalWorkDay: In many business systems, orders over weekends
                                       tend to be fewer than on weekdays. This number
                                       serves as a factor to accomdate for this in a
                                       realistic manner. For example, if this number
                                       is set to 25, it means create 25% of the orders
                                       from the AverageNumberOfCustomerOrdersPerDay
                                       parameter.

    SundayPercentageOfNormalWorkDay: Works the same as the previous parameter, but
                                     for Sundays

    UpdateCustomFields: The system has a few JSON style fields for use in demonstrating
                        new SQL Server 2016 functionality. A value of 1 indicates these
                        should be updated. These run pretty fast, so it's generally
                        best to just leave this parameter as is.

    IsSilentMode: A value of 0 means don't run in silent mode, in other words the
                  procedure will display status messages as it updates.

    AreDatesPrinted: A value of 1 indicates the procedure should display the current
                     date that is being processed. Note this parameter is being
                     depricated in future releases.
*/
EXEC DataLoadSimulation.DailyProcessToCreateHistory
    @StartDate = '20200101',
    @EndDate = '20200201',
    @AverageNumberOfCustomerOrdersPerDay = 30,
    @SaturdayPercentageOfNormalWorkDay = 25,
    @SundayPercentageOfNormalWorkDay = 0,
    @UpdateCustomFields = 1,
    @IsSilentMode = 0,
    @AreDatesPrinted = 1;
GO

:r .\pds400-ins-unkown-orderline.sql
:r .\pds410-update-archive-tables.sql

/*
  There is one other stored procedure you may find useful:
  DataLoadSimulation.PopulateDataToCurrentDate

  That procedure will update the database with sample data, starting
  with whatever the maximum date value is from the sample data and
  going through the current date on your computer.

  This is a great tool for keeping your sample database "current"
  with demonstration data. The parameters for it work the same
  as they do for DailyProcessToCreateHistory
*/


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