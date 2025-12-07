------------------------------------------------------------------------
-- Run this script on a SQL Server 2025 instance (or higher) to       --
-- create a database named OptimizedLocking if it doesn't exists      --
------------------------------------------------------------------------

USE [master];
GO

CREATE DATABASE [OptimizedLocking];
GO

ALTER DATABASE [OptimizedLocking] SET COMPATIBILITY_LEVEL = 170;
ALTER DATABASE [OptimizedLocking] SET RECOVERY SIMPLE;
ALTER DATABASE [OptimizedLocking] SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE [OptimizedLocking] SET ACCELERATED_DATABASE_RECOVERY = ON;
ALTER DATABASE [OptimizedLocking] SET READ_COMMITTED_SNAPSHOT ON;
ALTER DATABASE [OptimizedLocking] SET OPTIMIZED_LOCKING = ON;

USE [OptimizedLocking]
GO

IF NOT EXISTS (
                SELECT
                  [name]
                FROM
                  sys.filegroups
                WHERE
                  (is_default = 1) 
                  AND ([name] = N'PRIMARY')
              )
  ALTER DATABASE [OptimizedLocking] MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

SELECT
  [name]
  ,ADR  = is_accelerated_database_recovery_on
  ,RCSI = is_read_committed_snapshot_on
  ,OL = is_optimized_locking_on
FROM
  sys.databases
WHERE
  [name] = DB_NAME();
GO