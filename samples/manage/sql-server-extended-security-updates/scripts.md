![](./media/solutions-microsoft-logo-small.png)

#  ESU registration script examples

Microsoft shares example scripts in [T-SQL](#tsql) and [Powershell](#ps) that can generate the required SQL Server instance registration information. The Powershell samples create a CSV file that can be used to bulk register SQL Server instances covered by an ESU subscription.

## <a name="tsql"></a> T-SQL
To collect registration information from a **single instance**, you can use the example T-SQL script [EOS_DataGenerator_SingleInstance.sql](./scripts/EOS_DataGenerator_SingleInstance.sql) below:

```sql
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
```
**Note**: Verify if the **Host Type** is correct for your SQL Server instance.

## <a name="ps"></a> Powershell

To collect registration information from **all instances in a single machine**, you can use the example Powershell script [EOS_DataGenerator_LocalDiscovery.ps1](./scripts/EOS_DataGenerator_LocalDiscovery.ps1). Can be used in an Azure VM, on-premises physical server or on-premises VM.

**Note**: Verify if the **Host Type** is correct for your SQL Server instance before uploading the CSV file.

To collect registration information from **all instances listed in a text file**, you can use the example Powershell script [EOS_DataGenerator_InputList.ps1](./scripts/EOS_DataGenerator_InputList.ps1). Refer to [ServerInstances.txt](./scripts/ServerInstances.txt) for an input text file example.

**Note**: Verify if the **Host Type** is correct for your SQL Server instance before uploading the CSV file.
