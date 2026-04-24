-- ================================================
-- Template generated from Template Explorer using:
-- Configure Resource Governor.sql
--
-- Use the Specify Values for Template Parameters
-- command (Ctrl-Shift-M) to fill in the parameter
-- values below.
--
-- This template creates "admin" workload group
-- which uses "admin" resource pool and creates
-- corresponding classifier function which puts
-- sysadmins in such group
-- ================================================
-- Classifier functions for the Resource Governor must
-- reside within the master database.
USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create resource pool to be used
CREATE RESOURCE POOL <Pool_Name, sysname, poolAdmin>
WITH (
	-- allocate at least <MIN_CPU_PERCENT, int, 10>% of the CPU bandwidth for admin queries
	MIN_CPU_PERCENT = <MIN_CPU_PERCENT, int, 10>
	-- do not let them exceed <MAX_CPU_PERCENT, int, 30>% either
	, MAX_CPU_PERCENT = <MAX_CPU_PERCENT, int, 30>
	-- admin queries should be small and we will allocate about <MIN_MEMORY_PERCENT, int, 5>%
	-- of the server memory for them
	, MIN_MEMORY_PERCENT = <MIN_MEMORY_PERCENT, int, 5>
	, MAX_MEMORY_PERCENT = <MAX_MEMORY_PERCENT, int, 5>
)
GO

-- TODO
-- Create additional resource pools here

-- Create admin workload group
CREATE WORKLOAD GROUP <Group_Name, sysname, groupAdmin>
WITH (
	-- use all defaults
	IMPORTANCE = <IMPORTANCE, const, MEDIUM>
	, REQUEST_MAX_MEMORY_GRANT_PERCENT = <REQUEST_MAX_MEMORY_GRANT_PERCENT, int, 25>
	, REQUEST_MEMORY_GRANT_TIMEOUT_SEC = <REQUEST_MEMORY_GRANT_TIMEOUT_SEC, int, 0>
	, REQUEST_MAX_CPU_TIME_SEC = <REQUEST_MAX_CPU_TIME_SEC, int, 0>
	, MAX_DOP = <MAX_DOP, int, 0>
	, GROUP_MAX_REQUESTS = <GROUP_MAX_REQUESTS, int, 0>
)
USING
	<Pool_Name, sysname, poolAdmin>
GO

-- TODO
-- Create additional workload groups here

CREATE FUNCTION <Classifier_UDF_Name, sysname, [dbo].[rgClassifier]>()
RETURNS sysname
WITH SCHEMABINDING
AS
BEGIN
     -- Define the return sysname variable for the function
     DECLARE @grp_name AS sysname;
     SET @grp_name = 'default';

     -- Specify the T-SQL statements for mapping session information
     -- with Workload Groups defined for the Resource Governor.
     IF (IS_SRVROLEMEMBER ('sysadmin') = 1)
          SET @grp_name = '<Group_Name, sysname, groupAdmin>';

	-- TODO
	-- Put additional classification logic here
     RETURN @grp_name;
END
GO

-- Set the classifier function for Resource Governor
ALTER RESOURCE GOVERNOR
WITH (
	CLASSIFIER_FUNCTION = <Classifier_UDF_Name, sysname, [dbo].[rgClassifier]>
)
GO

-- Make changes effective
ALTER RESOURCE GOVERNOR RECONFIGURE
GO