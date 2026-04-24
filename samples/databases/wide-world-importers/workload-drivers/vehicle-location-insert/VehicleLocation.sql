-- This script enables the database for In-Memory OLTP if it is not already.
-- Then, it creates comparable disk-based and memory-optimized tables, as well as corresponding stored procedures
--   for vehicle location insertion.


SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. validate that In-Memory OLTP is supported
IF SERVERPROPERTY(N'IsXTPSupported') = 0
BEGIN
    PRINT N'Error: In-Memory OLTP is not supported for this server edition or database pricing tier.';
END
IF DB_ID() < 5
BEGIN
    PRINT N'Error: In-Memory OLTP is not supported in system databases. Connect to a user database.';
END
ELSE
BEGIN
	BEGIN TRY;
-- 2. add MEMORY_OPTIMIZED_DATA filegroup when not using Azure SQL DB
	IF SERVERPROPERTY('EngineEdition') != 5
	BEGIN
		DECLARE @SQLDataFolder nvarchar(max) = cast(SERVERPROPERTY('InstanceDefaultDataPath') as nvarchar(max))
		DECLARE @MODName nvarchar(max) = DB_NAME() + N'_mod';
		DECLARE @MemoryOptimizedFilegroupFolder nvarchar(max) = @SQLDataFolder + @MODName;

		DECLARE @SQL nvarchar(max) = N'';

		-- add filegroup
		IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE type = N'FX')
		BEGIN
			SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILEGROUP ' + QUOTENAME(@MODName) + N' CONTAINS MEMORY_OPTIMIZED_DATA;';
			EXECUTE (@SQL);

			-- add container in the filegroup
			IF NOT EXISTS (SELECT * FROM sys.database_files WHERE data_space_id IN (SELECT data_space_id FROM sys.filegroups WHERE type = N'FX'))
			BEGIN
				SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILE (name = N''' + @MODName + ''', filename = '''
						+ @MemoryOptimizedFilegroupFolder + N''')
TO FILEGROUP ' + QUOTENAME(@MODName);
				EXECUTE (@SQL);
			END
		END;
	END

	-- 3. set compat level to 130 if it is lower
	IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) < 130
		ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130

	-- 4. enable MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT for the database
	ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;


    END TRY
    BEGIN CATCH
        PRINT N'Error enabling In-Memory OLTP';
		IF XACT_STATE() != 0
			ROLLBACK;
        THROW;
    END CATCH;
END;

DROP PROCEDURE IF EXISTS InMemory.Insert500ThousandVehicleLocations
DROP PROCEDURE IF EXISTS InMemory.InsertVehicleLocation
DROP PROCEDURE IF EXISTS OnDisk.InsertVehicleLocation
DROP TABLE IF EXISTS InMemory.VehicleLocations
DROP TABLE IF EXISTS OnDisk.VehicleLocations
GO
DROP SCHEMA IF EXISTS InMemory
DROP SCHEMA IF EXISTS OnDisk
GO

-- We then create the disk based table and insert stored procedure
CREATE SCHEMA OnDisk AUTHORIZATION dbo;
GO

CREATE TABLE OnDisk.VehicleLocations
(
	VehicleLocationID bigint IDENTITY(1,1) PRIMARY KEY,
	RegistrationNumber nvarchar(20) NOT NULL,
	TrackedWhen datetime2(2) NOT NULL,
	Longitude decimal(18,4) NOT NULL,
	Latitude decimal(18,4) NOT NULL
);
GO

CREATE PROCEDURE OnDisk.InsertVehicleLocation
@RegistrationNumber nvarchar(20),
@TrackedWhen datetime2(2),
@Longitude decimal(18,4),
@Latitude decimal(18,4)
WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	INSERT OnDisk.VehicleLocations
		(RegistrationNumber, TrackedWhen, Longitude, Latitude)
	VALUES
		(@RegistrationNumber, @TrackedWhen, @Longitude, @Latitude);
	RETURN 0;
END;
GO

-- And then in-memory and natively-compiled alternatives

CREATE SCHEMA InMemory AUTHORIZATION dbo;
GO

CREATE TABLE InMemory.VehicleLocations
(
	VehicleLocationID bigint IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	RegistrationNumber nvarchar(20) NOT NULL,
	TrackedWhen datetime2(2) NOT NULL,
	Longitude decimal(18,4) NOT NULL,
	Latitude decimal(18,4) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

CREATE PROCEDURE InMemory.InsertVehicleLocation
@RegistrationNumber nvarchar(20),
@TrackedWhen datetime2(2),
@Longitude decimal(18,4),
@Latitude decimal(18,4)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'English'
)

	INSERT InMemory.VehicleLocations
		(RegistrationNumber, TrackedWhen, Longitude, Latitude)
	VALUES
		(@RegistrationNumber, @TrackedWhen, @Longitude, @Latitude);
	RETURN 0;
END;
GO
