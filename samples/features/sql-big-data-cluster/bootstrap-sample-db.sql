USE master;  
GO
-- Enable external scripts execution for R/Python/Java:
DECLARE @config_option nvarchar(100) = 'external scripts enabled';
IF NOT EXISTS(SELECT * FROM sys.configurations WHERE name = @config_option and value_in_use = 1)
BEGIN
	EXECUTE sp_configure @config_option, 1;
	RECONFIGURE WITH OVERRIDE;
END;
GO

-- Enable option to allow INSERT against external table defined on HADOOP data source
DECLARE @config_option nvarchar(100) = 'allow polybase export';
IF NOT EXISTS(SELECT * FROM sys.configurations WHERE name = @config_option and value_in_use = 1)
BEGIN
	EXECUTE sp_configure @config_option, 1;
	RECONFIGURE WITH OVERRIDE;
END;
GO

CREATE OR ALTER PROCEDURE #restore_database (@backup_file nvarchar(255), @db_name nvarchar(128))
AS
BEGIN
	DECLARE @restore_filelist_tmpl nvarchar(1000) = N'RESTORE FILELISTONLY FROM  DISK = N''/var/opt/mssql/data/%F''';
	DECLARE @restore_database_tmpl nvarchar(1000) = N'RESTORE DATABASE [%D] FROM  DISK = N''/var/opt/mssql/data/%F'' WITH FILE = 1';
	DECLARE @move_tmpl nvarchar(1000) = N', MOVE N''%L'' TO N''/var/opt/mssql/data/%F''';
	DECLARE @restore_cmd nvarchar(4000), @logical_name nvarchar(128), @filename nvarchar(260), @restore_cur CURSOR;
	DECLARE @files TABLE (
		[LogicalName]           NVARCHAR(128),
		[PhysicalName]          NVARCHAR(260),
		[Type]                  CHAR(1),
		[FileGroupName]         NVARCHAR(128),
		[Size]                  NUMERIC(20,0),
		[MaxSize]               NUMERIC(20,0),
		[FileID]                BIGINT,
		[CreateLSN]             NUMERIC(25,0),
		[DropLSN]               NUMERIC(25,0),
		[UniqueID]              UNIQUEIDENTIFIER,
		[ReadOnlyLSN]           NUMERIC(25,0),
		[ReadWriteLSN]          NUMERIC(25,0),
		[BackupSizeInBytes]     BIGINT,
		[SourceBlockSize]       INT,
		[FileGroupID]           INT,
		[LogGroupGUID]          UNIQUEIDENTIFIER,
		[DifferentialBaseLSN]   NUMERIC(25,0),
		[DifferentialBaseGUID]  UNIQUEIDENTIFIER,
		[IsReadOnly]            BIT,
		[IsPresent]             BIT,
		[TDEThumbprint]         VARBINARY(32),
		[SnapshotUrl]			NVARCHAR(260)
	)
	SET @restore_cmd = REPLACE(@restore_filelist_tmpl, '%F', @backup_file);
	INSERT INTO @files
	EXECUTE(@restore_cmd);

	SET @restore_cmd = REPLACE(REPLACE(@restore_database_tmpl, '%F', @backup_file), '%D', @db_name);
	SET @restore_cur = CURSOR FAST_FORWARD FOR SELECT LogicalName, REVERSE(LEFT(REVERSE(PhysicalName), CHARINDEX('\', REVERSE(PhysicalName))-1)) FROM @files;
	OPEN @restore_cur;
	WHILE(1=1)
	BEGIN
		FETCH FROM @restore_cur INTO @logical_name, @filename;
		IF @@FETCH_STATUS < 0 BREAK;

		SET @restore_cmd += REPLACE(REPLACE(@move_tmpl, '%L', @logical_name), '%F', @filename);
	END;
	EXECUTE(@restore_cmd);
END;
GO

CREATE OR ALTER PROCEDURE #create_data_sources
AS
BEGIN
	-- Create database master key (required for database scoped credentials used in the samples)
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'sql19bigdatacluster!';

	-- Create default data sources for SQL Big Data Cluster
	CREATE EXTERNAL DATA SOURCE SqlComputePool
	WITH (LOCATION = 'sqlcomputepool://controller-svc/default');

	CREATE EXTERNAL DATA SOURCE SqlDataPool
	WITH (LOCATION = 'sqldatapool://controller-svc/default');

	CREATE EXTERNAL DATA SOURCE SqlStoragePool
	WITH (LOCATION = 'sqlhdfs://controller-svc/default');

	CREATE EXTERNAL DATA SOURCE HadoopData
	WITH(
			TYPE=HADOOP,
			LOCATION='hdfs://nmnode-0-svc:9000/',
			RESOURCE_MANAGER_LOCATION='sparkhead-svc:8032'
	);
END;
GO

--- Sample dbs:
DECLARE @sample_dbs CURSOR, @proc nvarchar(255);
SET @sample_dbs = CURSOR FAST_FORWARD FOR
					SELECT file_or_directory_name, d.db_name
					FROM sys.dm_os_enumerate_filesystem('/var/opt/mssql/data', '*.bak') as f
					CROSS APPLY (VALUES(REPLACE(REPLACE(file_or_directory_name, 'tpcxbb_1gb', 'sales'), '.bak', ''))) as d(db_name)
					WHERE DB_ID(d.db_name) IS NULL;
DECLARE @file nvarchar(260), @db_name nvarchar(128);														
OPEN @sample_dbs;
WHILE(1=1)
BEGIN
	FETCH @sample_dbs INTO @file, @db_name;
	IF @@FETCH_STATUS < 0 BREAK;

	-- Restore the sample databases:
	EXECUTE #restore_database @file, @db_name;

	-- Create context for database:
	SET @proc = CONCAT(QUOTENAME(@db_name), N'.sys.sp_executesql');
	EXECUTE @proc N'#create_data_sources';

	-- Set compatibility level to 150:
	EXECUTE @proc N'ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150';

	-- Check for HADR & add database to containedag:
	IF SERVERPROPERTY('IsHadrEnabled') = 1
	BEGIN
		DECLARE @command nvarchar(1000);
		IF EXISTS(SELECT * FROM sys.databases WHERE name = @db_name and recovery_model_desc <> 'FULL')
			-- Set recovery to full
			EXECUTE @proc N'ALTER DATABASE CURRENT SET RECOVERY FULL';

		-- Workaround to avoid hk snapshot backup error (happens with wwidw & awdw dbs)
		BEGIN TRY
			-- Perform database & log backup to file to start a new chain
			BACKUP DATABASE @db_name TO DISK = 'NUL' WITH INIT, FORMAT;
		END TRY
		BEGIN CATCH
			-- Retry backup again
			BACKUP DATABASE @db_name TO DISK = 'NUL' WITH INIT, FORMAT;
		END CATCH;

		BACKUP LOG @db_name TO DISK = 'NUL' WITH INIT, FORMAT;

		-- Add database to AG
		SET @command = CONCAT(N'ALTER AVAILABILITY GROUP containedag ADD DATABASE ', QUOTENAME(@db_name));
		EXEC(@command);
	END;
END;
GO

USE sales;
GO

-- Create view used for ML services training and scoring stored procedures
CREATE OR ALTER  VIEW [dbo].[web_clickstreams_book_clicks]
AS
	SELECT
        /* There is a bug in TPCx-BB data generator which results in data where all users have purchased books.
        As a result, we cannot use the data as is for ML training purposes. So we will treat users with 1-5 clicks
		in the book category as not interested in books. */
	  CASE WHEN q.clicks_in_category < 6 THEN 0 ELSE q.clicks_in_category END AS clicks_in_category,
	  CASE WHEN cd.cd_education_status IN ('Advanced Degree', 'College', '4 yr Degree', '2 yr Degree') THEN 1 ELSE 0 END AS college_education,
	  CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END AS male,
	  COALESCE(cd.cd_credit_rating, 'Unknown') as cd_credit_rating,
	  q.clicks_in_1,
	  q.clicks_in_2,
	  q.clicks_in_3,
	  q.clicks_in_4,
	  q.clicks_in_5,
	  q.clicks_in_6,
	  q.clicks_in_7,
	  q.clicks_in_8,
	  q.clicks_in_9
	FROM( 
	  SELECT 
		w.wcs_user_sk,
		SUM( CASE WHEN i.i_category = 'Books' THEN 1 ELSE 0 END) AS clicks_in_category,
		SUM( CASE WHEN i.i_category_id = 1 THEN 1 ELSE 0 END) AS clicks_in_1,
		SUM( CASE WHEN i.i_category_id = 2 THEN 1 ELSE 0 END) AS clicks_in_2,
		SUM( CASE WHEN i.i_category_id = 3 THEN 1 ELSE 0 END) AS clicks_in_3,
		SUM( CASE WHEN i.i_category_id = 4 THEN 1 ELSE 0 END) AS clicks_in_4,
		SUM( CASE WHEN i.i_category_id = 5 THEN 1 ELSE 0 END) AS clicks_in_5,
		SUM( CASE WHEN i.i_category_id = 6 THEN 1 ELSE 0 END) AS clicks_in_6,
		SUM( CASE WHEN i.i_category_id = 7 THEN 1 ELSE 0 END) AS clicks_in_7,
		SUM( CASE WHEN i.i_category_id = 8 THEN 1 ELSE 0 END) AS clicks_in_8,
		SUM( CASE WHEN i.i_category_id = 9 THEN 1 ELSE 0 END) AS clicks_in_9
	  FROM web_clickstreams as w
	  INNER JOIN item as i ON (w.wcs_item_sk = i_item_sk
						 AND w.wcs_user_sk IS NOT NULL)
	  GROUP BY w.wcs_user_sk
	) AS q
	INNER JOIN customer as c ON q.wcs_user_sk = c.c_customer_sk
	INNER JOIN customer_demographics as cd ON c.c_current_cdemo_sk = cd.cd_demo_sk;
GO

-- Create table for storing the ML models
DROP TABLE IF EXISTS sales_models;
CREATE TABLE sales_models (
	model_name varchar(100) PRIMARY KEY,
	model varbinary(max) NOT NULL,
	model_native varbinary(max) NULL,
	created_by nvarchar(500) NOT NULL DEFAULT(SYSTEM_USER),
	create_time datetime2 NOT NULL DEFAULT(SYSDATETIME())
);
GO
