-- Correct imported policies

-- Update existing condition name to match other similar conditions. All current policies using the below condition will update automatically.
EXEC msdb.dbo.sp_syspolicy_rename_condition @name = N'SQL Server 2005 or a Later Version', @new_name = N'SQL Server Version 2005 or a Later Version';
GO

/*
Notes:
Remove from "Surface Area Configuration for Database Engine 2005 and 2000 Features" condition all 2005 only features.
Then change "Surface Area Configuration for Database Engine 2008 Features" to apply from SQL 2005 onwards, otherwise policy evaluation fails.
*/

EXEC msdb.dbo.sp_syspolicy_update_condition @name = N'Surface Area Configuration for Database Engine 2005 and 2000 Features', @description=N'Confirms that the default surface area settings are set for Database 2000 Engine features.', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>AND</OpType>
    <Count>2</Count>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>AND</OpType>
      <Count>2</Count>
      <Operator>
        <TypeClass>Bool</TypeClass>
        <OpType>AND</OpType>
        <Count>2</Count>
        <Operator>
          <TypeClass>Bool</TypeClass>
          <OpType>EQ</OpType>
          <Count>2</Count>
          <Attribute>
            <TypeClass>Bool</TypeClass>
            <Name>AdHocRemoteQueriesEnabled</Name>
          </Attribute>
          <Function>
            <TypeClass>Bool</TypeClass>
            <FunctionType>False</FunctionType>
            <ReturnType>Bool</ReturnType>
            <Count>0</Count>
          </Function>
        </Operator>
        <Operator>
          <TypeClass>Bool</TypeClass>
          <OpType>EQ</OpType>
          <Count>2</Count>
          <Attribute>
            <TypeClass>Bool</TypeClass>
            <Name>OleAutomationEnabled</Name>
          </Attribute>
          <Function>
            <TypeClass>Bool</TypeClass>
            <FunctionType>False</FunctionType>
            <ReturnType>Bool</ReturnType>
            <Count>0</Count>
          </Function>
        </Operator>
      </Operator>
      <Operator>
        <TypeClass>Bool</TypeClass>
        <OpType>EQ</OpType>
        <Count>2</Count>
        <Attribute>
          <TypeClass>Bool</TypeClass>
          <Name>SqlMailEnabled</Name>
        </Attribute>
        <Function>
          <TypeClass>Bool</TypeClass>
          <FunctionType>False</FunctionType>
          <ReturnType>Bool</ReturnType>
          <Count>0</Count>
        </Function>
      </Operator>
    </Operator>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>EQ</OpType>
      <Count>2</Count>
      <Attribute>
        <TypeClass>Bool</TypeClass>
        <Name>WebAssistantEnabled</Name>
      </Attribute>
      <Function>
        <TypeClass>Bool</TypeClass>
        <FunctionType>False</FunctionType>
        <ReturnType>Bool</ReturnType>
        <Count>0</Count>
      </Function>
    </Operator>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Bool</TypeClass>
      <Name>XPCmdShellEnabled</Name>
    </Attribute>
    <Function>
      <TypeClass>Bool</TypeClass>
      <FunctionType>False</FunctionType>
      <ReturnType>Bool</ReturnType>
      <Count>0</Count>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N''
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name=N'Surface Area Configuration for Database Engine 2005 and 2000 Features', @root_condition_name=N'SQL Server Version 2000'
GO
EXEC msdb.dbo.sp_syspolicy_rename_policy @name = N'Surface Area Configuration for Database Engine 2005 and 2000 Features', @new_name = N'Surface Area Configuration for Database Engine 2000 Features';
GO
EXEC msdb.dbo.sp_syspolicy_rename_condition @name = N'Surface Area Configuration for Database Engine 2005 and 2000 Features', @new_name = N'Surface Area Configuration for Database Engine 2000 Features';
GO

EXEC msdb.dbo.sp_syspolicy_update_condition @name = N'Surface Area Configuration for Database Engine 2008 Features', @description=N'Confirms that the default surface area settings are set for Database 2005 and above Engine features.', @is_name_condition=0, @obj_name=N''
GO
EXEC msdb.dbo.sp_syspolicy_update_policy @name=N'Surface Area Configuration for Database Engine 2008 Features', @root_condition_name=N'SQL Server Version 2005 or a Later Version'
GO
EXEC msdb.dbo.sp_syspolicy_rename_policy @name = N'Surface Area Configuration for Database Engine 2008 Features', @new_name = N'Surface Area Configuration for Database Engine Features';
GO
EXEC msdb.dbo.sp_syspolicy_rename_condition @name = N'Surface Area Configuration for Database Engine 2008 Features', @new_name = N'Surface Area Configuration for Database Engine Features';
GO

/*
Note:
"Surface Area Configuration for Service Broker Endpoints" and "Surface Area Configuration for SOAP Endpoints" fails on SQL 2000
*/
EXEC msdb.dbo.sp_syspolicy_update_policy @name = N'Surface Area Configuration for Service Broker Endpoints', @root_condition_name=N'SQL Server Version 2005 or a Later Version'
GO
EXEC msdb.dbo.sp_syspolicy_update_policy @name = N'Surface Area Configuration for SOAP Endpoints', @root_condition_name=N'SQL Server Version 2005 or a Later Version'
GO

/*
Note:
"Public Not Granted Server Permissions" fails on SQL 2000
*/
EXEC msdb.dbo.sp_syspolicy_update_policy @name='Public Not Granted Server Permissions', @root_condition_name=N'SQL Server Version 2005 or a Later Version'
GO

-- Fix typos or extra white spaces in descriptions
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Affinity Mask', @description=N'Checks an instance of SQL Server for setting, affinity mask to its default value 0, since in most cases, the Microsoft Windows 2000 or Windows Server 2003 default affinity provides the best performance.
Confirms whether the setting affinity mask of server is set to zero.'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Last Successful Backup Date', @description=N'Checks whether a database has recent backups. Scheduling regular backups is important for protecting your databases against data loss from a variety of failures.
The appropriate frequency for backing up data depends on the recovery model of the database, on business requirements regarding potential data loss, and on how frequently the database is updated. In a frequently updated database, the amount of work-loss exposure increases relatively quickly between backups.
The best practice is to perform backups frequently enough to protect databases against data loss. The simple recovery model and full recovery model both require data backups. The full recovery model also requires log backups, which should be taken more often than data backups. For either recovery model, you can supplement your full backups with differential backups to efficiently reduce the risk of data loss. For a database that uses the full recovery model, Microsoft recommends that you take frequent log backups. For a production database that contains critical data, log backups would typically be taken every one to fifteen minutes. Note: The recommended method for scheduling backups is a database maintenance plan.                    '
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log Cluster Disk Resource Corruption Error', @description=N'Detects SCSI host adapter configuration issues or a malfunctioning device error message in the System Log.
http://support.microsoft.com/kb/311081'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log Device Driver Control Error', @description=N'Detects Error EventID �11 in the System Log. This error could be because of a corrupted device driver, a hardware problem, a malfunctioning device, poor cabling, or termination issues.
http://support.microsoft.com/kb/259237
http://support.microsoft.com/kb/154690'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log Device Not Ready Error', @description=N'This policy detects for error messages in Detects error messages in the System Log that can be the result of SCSI host adapter configuration issues or related problems.
http://support.microsoft.com/kb/259237
http://support.microsoft.com/kb/154690'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log Disk Defragmentation', @description=N'This policy detects error message in System Log Detects an error message in the System Log that can result when the Windows 2000 disk defragmenter tool does not move a particular data element, and schedules Chkdsk.exe. In this condition, the error is a false positive. There is no loss of data, and, the integrity of the data is not affected.
http://support.microsoft.com/kb/885688
http://support.microsoft.com/kb/320866'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log Failed I/O Request Error', @description=N' This policy detects a failed I/O request error message in the system log. This could be the result of a variety of things, including a firmware bug or faulty SCSI cables.
http://support.microsoft.com/kb/311081
http://support.microsoft.com/kb/885688'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log I/O Error During Hard Page Fault Error', @description=N'Detects I/O Error during hard page fault in System Log.
http://support.microsoft.com/kb/304415
http://support.microsoft.com/kb/305547'
GO

EXEC msdb.dbo.sp_syspolicy_update_policy @name='Windows Event Log Storage System I/O Timeout Error', @description=N'Detects Error EventID �9 in the System Log. This error indicates that I/O time-out has occurred within the storage system, as detected from the driver for the controlle
http://support.microsoft.com/kb/259237
http://support.microsoft.com/kb/154690'
GO