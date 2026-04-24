-- SQL 2019

-- Restore AdventureWorks
RESTORE DATABASE [AdventureWorks]
FROM  DISK = N'F:\MSSQL\MSSQL15.SQL2019\MSSQL\Backup\AdventureWorks2016_EXT.bak'
WITH  FILE = 1
	,  MOVE N'AdventureWorks2016_EXT_Data' TO N'F:\MSSQL\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks_Data.mdf'
	,  MOVE N'AdventureWorks2016_EXT_Log' TO N'F:\MSSQL\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks_Log.ldf'
	,  MOVE N'AdventureWorks2016_EXT_mod' TO N'F:\MSSQL\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks_mod'
	,  NOUNLOAD,  STATS = 5


-- Turn off auto stats
USE [master]
GO
ALTER DATABASE [AdventureWorks] SET AUTO_CREATE_STATISTICS OFF
GO
ALTER DATABASE [AdventureWorks] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT
GO

-- Upgrade compatibility
ALTER DATABASE AdventureWorks
SET COMPATIBILITY_LEVEL = 150;
GO
