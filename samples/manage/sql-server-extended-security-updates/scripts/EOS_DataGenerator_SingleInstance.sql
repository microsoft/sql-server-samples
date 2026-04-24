DECLARE @SystemManufacturer NVARCHAR(128), @Edition NVARCHAR(20), @HostType NVARCHAR(30), @Cores int, @SQLVersion NVARCHAR(50)
DECLARE @machineinfo TABLE ([Value] NVARCHAR(256), [Data] NVARCHAR(256))

INSERT INTO @machineinfo
EXEC xp_instance_regread 'HKEY_LOCAL_MACHINE','HARDWARE\DESCRIPTION\System\BIOS','SystemManufacturer';
SELECT @SystemManufacturer = [Data] FROM @machineinfo WHERE [Value] = 'SystemManufacturer';
SET @HostType = 'Physical Server'
IF LOWER(@SystemManufacturer) = 'microsoft' OR LOWER(@SystemManufacturer) = 'vmware'
SET @HostType = 'Virtual Machine'

SELECT @Cores = hyperthread_ratio FROM sys.dm_os_sys_info;
SELECT @Edition = CONVERT(NVARCHAR(20), SERVERPROPERTY('Edition'))
SELECT @SQLVersion = CONVERT(NVARCHAR(50), SERVERPROPERTY('ProductVersion'))

SELECT SERVERPROPERTY('ServerName') AS [name],
	CASE LEFT(@SQLVersion,4) WHEN '10.0' THEN '2008'
		WHEN '10.5' THEN '2008R2'
		WHEN '11.0' THEN '2012'
		WHEN '12.0' THEN '2014'
		WHEN '13.0' THEN '2016'
		WHEN '14.0' THEN '2017'
		WHEN '15.0' THEN '2019'
		ELSE 'Other'
		END AS [version],
	LEFT(@Edition,CHARINDEX(' ', @Edition,0)-1) AS edition,
	@Cores AS cores,
	@HostType AS hostType;
