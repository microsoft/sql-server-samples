-- Add or rename policy categories to be used by new and/or existing imported policies
DECLARE @policy_category_id int;
EXEC msdb.dbo.sp_syspolicy_add_policy_category @name = N'Microsoft Best Practices: Version Audit', @mandate_database_subscriptions = 1, @policy_category_id = @policy_category_id OUTPUT;
GO

DECLARE @policy_category_id int;
EXEC msdb.dbo.sp_syspolicy_add_policy_category @name = N'Microsoft Best Practices: Database Configurations', @mandate_database_subscriptions = 1, @policy_category_id = @policy_category_id OUTPUT;
GO

DECLARE @policy_category_id int;
EXEC msdb.dbo.sp_syspolicy_add_policy_category @name = N'Microsoft Best Practices: Database Design', @mandate_database_subscriptions = 1, @policy_category_id = @policy_category_id OUTPUT;
GO

DECLARE @policy_category_id int;
EXEC msdb.dbo.sp_syspolicy_add_policy_category @name = N'Disabled', @mandate_database_subscriptions = 1, @policy_category_id = @policy_category_id OUTPUT;
GO

EXEC msdb.dbo.sp_syspolicy_rename_policy_category @name = N'Microsoft Best Practices: Configuration', @new_name = N'Microsoft Best Practices: Server Configuration'
GO

-- Change imported policies categories
EXEC msdb.dbo.sp_syspolicy_update_policy @name='Data and Log File Location', @policy_category=N'Microsoft Best Practices: Database Configurations'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='Database Auto Close', @policy_category=N'Microsoft Best Practices: Database Configurations'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='Database Auto Shrink', @policy_category=N'Microsoft Best Practices: Database Configurations'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='Database Collation', @policy_category=N'Microsoft Best Practices: Database Design'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server System Tables Updatable', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Affinity Mask', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Lightweight Pooling', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Dynamic Locks', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Max Worker Threads for SQL Server 2005 and above', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Network Packet Size', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Max Worker Threads for 32-bit SQL Server 2000', @policy_category=N'Microsoft Best Practices: Server Configuration'
EXEC msdb.dbo.sp_syspolicy_update_policy @name='SQL Server Max Worker Threads for 64-bit SQL Server 2000', @policy_category=N'Microsoft Best Practices: Server Configuration'
GO

-- Update existing condition name to match other similar conditions. All current policies using the below condition will update automatically.
EXEC msdb.dbo.sp_syspolicy_rename_condition @name = N'SQL Server 2005 or a Later Version', @new_name = N'SQL Server Version 2005 or a Later Version';
GO

-- Recommended CU or Hotfix
-- Note that condition has to be updated with proper build numbers for the policy to be relevant.
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Is Recommended Build', @description=N'Checks for the latest recommended CU or Hotfix (minor build number) on all SQL Server instances. Use article http://support.microsoft.com/kb/957826 to manually update minor build numbers with the latest CU for the specific versions and major builds.', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>SELECT CASE WHEN (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 8 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 2273) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 9 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 5324) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 10 AND CONVERT(int, (@@microsoftversion / 0x10000) &amp; 0xff) = 0 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 5861) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 10 AND CONVERT(int, (@@microsoftversion / 0x10000) &amp; 0xff) = 50 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 4319) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 11 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 5548) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 12 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 2402) THEN 1 ELSE 0 END AS [IsRecommendedBuild]</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>1</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Server_Recommended_Build_ObjectSet', @facet=N'Server', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Server_Recommended_Build_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server Recommended Build', @condition_name=N'Is Recommended Build', @policy_category=N'Microsoft Best Practices: Version Audit', @description=N'Service packs are the main delivery vehicle for fixes, security patches, and general improvements to the SQL Server system. These updates can protect you from as well as provide you with solutions to known issues. Therefore, applying service packs and hotfixes as soon as possible after thorough testing can greatly reduce your vulnerability to a wide range of issues. Additionally, because service packs often include improvements to performance supportability, and diagnostics, having the latest service packs installed can improve response in general and can reduce the amount of time necessary to diagnose and troubleshoot an issue.
Over time, a Cumulative Update (CU) package is created by the development team to address specific product issues affecting certain customers. These CU builds contain all fixes since the product or service pack is released as stated in the KB article associated with a specific CU package release. Sometimes the issue has a broad customer impact, security implications, or both. Thus, a General Distribution Release (GDR) is issued so that all customers can receive the updates.', @help_text=N'Where to find information about the latest SQL Server builds', @help_link=N'http://support.microsoft.com/kb/957826', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'SQL_Server_Recommended_Build_ObjectSet'
Select @policy_id
GO

Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Is Recommended Build for SQL 2000', @description=N'', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>VersionMajor</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>8</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>BuildNumber</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>2273</Value>
    </Constant>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Server_2000_Recommended_Build_ObjectSet', @facet=N'Server', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Server_2000_Recommended_Build_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server 2000 Recommended Build', @condition_name=N'Is Recommended Build for SQL 2000', @policy_category=N'Microsoft Best Practices: Version Audit', @description=N'Service packs are the main delivery vehicle for fixes, security patches, and general improvements to the SQL Server system. These updates can protect you from as well as provide you with solutions to known issues. Therefore, applying service packs and hotfixes as soon as possible after thorough testing can greatly reduce your vulnerability to a wide range of issues. Additionally, because service packs often include improvements to performance supportability, and diagnostics, having the latest service packs installed can improve response in general and can reduce the amount of time necessary to diagnose and troubleshoot an issue.
Over time, a Cumulative Update (CU) package is created by the development team to address specific product issues affecting certain customers. These CU builds contain all fixes since the product or service pack is released as stated in the KB article associated with a specific CU package release. Sometimes the issue has a broad customer impact, security implications, or both. Thus, a General Distribution Release (GDR) is issued so that all customers can receive the updates.', @help_text=N'Where to find information about the latest SQL Server builds', @help_link=N'http://support.microsoft.com/kb/957826', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2000', @object_set=N'SQL_Server_2000_Recommended_Build_ObjectSet'
Select @policy_id
GO


-- Latest SP
-- Note that condition has to be updated with proper build numbers for the policy to be relevant.
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Is Latest SP installed', @description=N'Checks for the latest SP (major build number) on all SQL Server instances.', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>SELECT CASE WHEN (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 8 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 2039) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 9 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 5000) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 10 AND CONVERT(int, (@@microsoftversion / 0x10000) &amp; 0xff) = 0 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 5500) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 10 AND CONVERT(int, (@@microsoftversion / 0x10000) &amp; 0xff) = 50 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 4000) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 11 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 5058) OR (CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) = 12 AND CONVERT(int, @@microsoftversion &amp; 0xffff) &gt;= 2000) THEN 1 ELSE 0 END AS [IsRecommendedBuild]</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>1</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Server_LatestSP_ObjectSet', @facet=N'Server', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Server_LatestSP_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server latest Service Pack', @condition_name=N'Is Latest SP installed', @policy_category=N'Microsoft Best Practices: Version Audit', @description=N'Service packs are the main delivery vehicle for fixes, security patches, and general improvements to the SQL Server system. These updates can protect you from as well as provide you with solutions to known issues. Therefore, applying service packs and hotfixes as soon as possible after thorough testing can greatly reduce your vulnerability to a wide range of issues. Additionally, because service packs often include improvements to performance supportability, and diagnostics, having the latest service packs installed can improve response in general and can reduce the amount of time necessary to diagnose and troubleshoot an issue.
Finally, support for older Microsoft SQL Server versions and service packs could be discontinued, thus leaving your system in an unsupported configuration. Thus, it is essential to apply all service packs as soon as possible.
Over time, a Cumulative Update (CU) package is created by the development team to address specific product issues affecting certain customers. These CU builds contain all fixes since the product or service pack is released as stated in the KB article associated with a specific CU package release. Sometimes the issue has a broad customer impact, security implications, or both. Thus, a General Distribution Release (GDR) is issued so that all customers can receive the updates.', @help_text=N'Microsoft Support Lifecycle', @help_link=N'http://support.microsoft.com/gp/lifecycle', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'SQL_Server_LatestSP_ObjectSet'
Select @policy_id
GO

Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Is Latest SP installed for SQL 2000', @description=N'', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>VersionMajor</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>8</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>BuildNumber</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>2039</Value>
    </Constant>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Server_2000_LatestSP_ObjectSet', @facet=N'Server', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Server_2000_LatestSP_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server 2000 latest Service Pack', @condition_name=N'Is Latest SP installed for SQL 2000', @policy_category=N'Microsoft Best Practices: Version Audit', @description=N'Service packs are the main delivery vehicle for fixes, security patches, and general improvements to the SQL Server system. These updates can protect you from as well as provide you with solutions to known issues. Therefore, applying service packs and hotfixes as soon as possible after thorough testing can greatly reduce your vulnerability to a wide range of issues. Additionally, because service packs often include improvements to performance supportability, and diagnostics, having the latest service packs installed can improve response in general and can reduce the amount of time necessary to diagnose and troubleshoot an issue.
Finally, support for older Microsoft SQL Server versions and service packs could be discontinued, thus leaving your system in an unsupported configuration. Thus, it is essential to apply all service packs as soon as possible.
Over time, a Cumulative Update (CU) package is created by the development team to address specific product issues affecting certain customers. These CU builds contain all fixes since the product or service pack is released as stated in the KB article associated with a specific CU package release. Sometimes the issue has a broad customer impact, security implications, or both. Thus, a General Distribution Release (GDR) is issued so that all customers can receive the updates.', @help_text=N'Microsoft Support Lifecycle', @help_link=N'http://support.microsoft.com/gp/lifecycle', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2000', @object_set=N'SQL_Server_2000_LatestSP_ObjectSet'
Select @policy_id
GO

-- Maintenance Jobs Deployed and Enabled
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Maintenance Jobs', @description=N'', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>ExecuteSql</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Numeric</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>SELECT COUNT([name]) FROM [msdb].[dbo].[sysjobs] WHERE [name] IN (''''ABD:U_AdaptativeIndexDefrag'''',''''ABD_U_AdaptiveIndexDefrag'''',''''ABD_U.AdaptiveIndexDefrag'''') AND  [enabled] = 1</Value>
      </Constant>
    </Function>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>1</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>ExecuteSql</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Numeric</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>SELECT COUNT([name]) FROM [msdb].[dbo].[sysjobs] WHERE [name] IN (''''ABD_U_WeeklyMaintenance'''',''''ABD_U.Weekly Maintenance'''') AND  [enabled] = 1</Value>
      </Constant>
    </Function>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>1</Value>
    </Constant>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

/*
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Maintenance Jobs', @description=N'', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>ExecuteSql</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Numeric</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>SELECT COUNT([name]) FROM [msdb].[dbo].[sysjobs] WHERE [name] = ''''Daily Index Defrag'''' AND  [enabled] = 1</Value>
      </Constant>
    </Function>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>1</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>ExecuteSql</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Numeric</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>SELECT COUNT([name]) FROM [msdb].[dbo].[sysjobs] WHERE [name] = ''''Weekly Maintenance'''' AND  [enabled] = 1</Value>
      </Constant>
    </Function>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>1</Value>
    </Constant>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO
*/

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Are_MaintenanceJobs_Deployed_and_Enabled_ObjectSet', @facet=N'Server', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Are_MaintenanceJobs_Deployed_and_Enabled_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Are Maintenance Jobs Deployed and Enabled', @condition_name=N'Maintenance Jobs', @policy_category=N'Microsoft Best Practices: Maintenance', @description=N'Index fragmentation occurs naturally as changes are made to data. Leverage AdaptiveIndexDefrag procedure for index defrag according to the objects needs, balancing index performance with minimal required time for this task, while being aware of all the common caveats linked to index defragmentation.
For recommendations on implementing automated maintenance tasks, from integrity checking to index defrag, among other maintenance tasks, please refer to the help link.', @help_text=N'', @help_link=N'http://blogs.msdn.com/b/blogdoezequiel/archive/2012/09/18/about-maintenance-plans-grooming-sql-server.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'Are_MaintenanceJobs_Deployed_and_Enabled_ObjectSet'
Select @policy_id
GO

-- Is log backup older than 24h
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Is Full RM and Log Backup older than 24h', @description=N'Checks for databases in Full recovery model, having Log backups older than 24h.', @facet=N'IDatabaseMaintenanceFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>RecoveryModel</Name>
    </Attribute>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>Enum</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Microsoft.SqlServer.Management.Smo.RecoveryModel</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Full</Value>
      </Constant>
    </Function>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>DateTime</TypeClass>
      <Name>LastLogBackupDate</Name>
    </Attribute>
    <Function>
      <TypeClass>DateTime</TypeClass>
      <FunctionType>DateAdd</FunctionType>
      <ReturnType>DateTime</ReturnType>
      <Count>3</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>hour</Value>
      </Constant>
      <Constant>
        <TypeClass>Numeric</TypeClass>
        <ObjType>System.Double</ObjType>
        <Value>-24</Value>
      </Constant>
      <Function>
        <TypeClass>DateTime</TypeClass>
        <FunctionType>GetDate</FunctionType>
        <ReturnType>DateTime</ReturnType>
        <Count>0</Count>
      </Function>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
SELECT @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'LogBackup_older_than_24h_ObjectSet', @facet=N'IDatabaseMaintenanceFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'LogBackup_older_than_24h_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Log Backup older than 24h', @condition_name=N'Is Full RM and Log Backup older than 24h', @policy_category=N'Microsoft Best Practices: Maintenance', @description=N'Some of the databases have already been backed up, but their logs have not been backed up in the last 24h, and these databases are not in simple recovery mode. For these database the inactive part of transaction log never gets truncated, the log keeps growing until it hits the disk space limits. In the case of disaster there is possible data loss as transaction logs are never backed-up.', @help_link=N'http://msdn.microsoft.com/en-us/library/ms191239.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'LogBackup_older_than_24h_ObjectSet'
Select @policy_id
GO

-- No full backups on read-write, full RM databases
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Is Full RM and no Backups on Read-Write DBs', @description=N'Check if no Backups were taken on read-write databases in Full recovery model.', @facet=N'IDatabaseMaintenanceFacet', @expression=N'<Operator>
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
        <TypeClass>Numeric</TypeClass>
        <Name>RecoveryModel</Name>
      </Attribute>
      <Function>
        <TypeClass>Numeric</TypeClass>
        <FunctionType>Enum</FunctionType>
        <ReturnType>Numeric</ReturnType>
        <Count>2</Count>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>Microsoft.SqlServer.Management.Smo.RecoveryModel</Value>
        </Constant>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>Full</Value>
        </Constant>
      </Function>
    </Operator>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>GT</OpType>
      <Count>2</Count>
      <Attribute>
        <TypeClass>DateTime</TypeClass>
        <Name>LastBackupDate</Name>
      </Attribute>
      <Function>
        <TypeClass>DateTime</TypeClass>
        <FunctionType>DateTime</FunctionType>
        <ReturnType>DateTime</ReturnType>
        <Count>1</Count>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>1900-01-01 00:00:00.000</Value>
        </Constant>
      </Function>
    </Operator>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Bool</TypeClass>
      <Name>ReadOnly</Name>
    </Attribute>
    <Function>
      <TypeClass>Bool</TypeClass>
      <FunctionType>False</FunctionType>
      <ReturnType>Bool</ReturnType>
      <Count>0</Count>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'No_Full_Bck_ObjectSet', @facet=N'IDatabaseMaintenanceFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'No_Full_Bck_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'No Full Backups', @condition_name=N'Is Full RM and no Backups on Read-Write DBs', @policy_category=N'Microsoft Best Practices: Maintenance', @description=N'Some of the databases have never been backed up, and these databases are not in simple recovery mode. In the case of disaster there is possible data loss as transaction logs are never backed-up.', @help_link=N'http://msdn.microsoft.com/en-us/library/ms191239.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'No_Full_Bck_ObjectSet'
Select @policy_id
GO

-- Service accounts must not match
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Service Accounts', @description=N'Checks for the same account in Database Engine, SQL Agent and SQL Browser.', @facet=N'IServerSetupFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>OR</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>OR</OpType>
    <Count>2</Count>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>NE</OpType>
      <Count>2</Count>
      <Attribute>
        <TypeClass>String</TypeClass>
        <Name>EngineServiceAccount</Name>
      </Attribute>
      <Attribute>
        <TypeClass>String</TypeClass>
        <Name>AgentServiceAccount</Name>
      </Attribute>
    </Operator>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>NE</OpType>
      <Count>2</Count>
      <Attribute>
        <TypeClass>String</TypeClass>
        <Name>EngineServiceAccount</Name>
      </Attribute>
      <Attribute>
        <TypeClass>String</TypeClass>
        <Name>BrowserServiceAccount</Name>
      </Attribute>
    </Operator>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>NE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>String</TypeClass>
      <Name>AgentServiceAccount</Name>
    </Attribute>
    <Attribute>
      <TypeClass>String</TypeClass>
      <Name>BrowserServiceAccount</Name>
    </Attribute>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Service_Accounts_must_not_match_ObjectSet', @facet=N'IServerSetupFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Service_Accounts_must_not_match_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Service Accounts must not match', @condition_name=N'Service Accounts', @policy_category=N'Microsoft Best Practices: Security', @description=N'Each service in SQL Server represents a process or a set of processes to manage authentication of SQL Server operations with Windows.
When choosing a service account, consider an account with the least amount of privileges needed to do the job and no more. This varies according to the service itself, whether it is Analysis Services, Integration Services or Reporting Services.
Change the service accounts per service according to each service minimum set of requirements, using the SQL Server Configuration Manager.
Always use SQL Server tools such as SQL Server Configuration Manager to change the account used by the various SQL Server services, or to change the password for the account.
For Analysis Services instances that you deploy in a SharePoint farm, always use SharePoint Central Administration to change the server accounts for PowerPivot service applications and the Analysis Services service.', @help_link=N'http://technet.microsoft.com/en-us/library/ms143504.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'Service_Accounts_must_not_match_ObjectSet'
Select @policy_id
GO

-- Is AutoUpdateStats Disabled and AutoUpdateStats Async Enabled?
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'AutoUpdateStats Disabled and AutoUpdateStats Async Enabled', @description=N'Checks if AutoUpdateStats is disabled and AutoUpdateStats Async is enabled, which does not automatically update statistics.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>SELECT CASE WHEN is_auto_update_stats_on = 0 AND is_auto_update_stats_async_on = 1 THEN 1 ELSE 0 END FROM master.sys.databases (NOLOCK) WHERE name = DB_NAME()</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>0</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'AutoUpdatesStatsAsync_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'AutoUpdatesStatsAsync_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'AutoUpdateStats Async Disabled', @condition_name=N'AutoUpdateStats Disabled and AutoUpdateStats Async Enabled', @policy_category=N'Microsoft Best Practices: Database Configurations', @description=N'Ensure that AUTO_UPDATE_STATISTICS is enabled for each user database on the Microsoft SQL Server instance on which AUTO_UPDATE_STATISTICS_ASYNC is also used. Async update requires AUTO_UPDATE_STATISTICS to be enabled.', @help_link=N'http://msdn.microsoft.com/en-us/library/ms190397.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'AutoUpdatesStatsAsync_ObjectSet'
Select @policy_id
GO

-- DB status
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Database Status', @description=N'Checks for database status that prevent database access.', @facet=N'IDatabaseMaintenanceFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>AND</OpType>
    <Count>2</Count>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>NE</OpType>
      <Count>2</Count>
      <Attribute>
        <TypeClass>Numeric</TypeClass>
        <Name>Status</Name>
      </Attribute>
      <Function>
        <TypeClass>Numeric</TypeClass>
        <FunctionType>Enum</FunctionType>
        <ReturnType>Numeric</ReturnType>
        <Count>2</Count>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>Microsoft.SqlServer.Management.Smo.DatabaseStatus</Value>
        </Constant>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>Suspect</Value>
        </Constant>
      </Function>
    </Operator>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>NE</OpType>
      <Count>2</Count>
      <Attribute>
        <TypeClass>Numeric</TypeClass>
        <Name>Status</Name>
      </Attribute>
      <Function>
        <TypeClass>Numeric</TypeClass>
        <FunctionType>Enum</FunctionType>
        <ReturnType>Numeric</ReturnType>
        <Count>2</Count>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>Microsoft.SqlServer.Management.Smo.DatabaseStatus</Value>
        </Constant>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>Inaccessible</Value>
        </Constant>
      </Function>
    </Operator>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>NE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>Status</Name>
    </Attribute>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>Enum</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Microsoft.SqlServer.Management.Smo.DatabaseStatus</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>EmergencyMode</Value>
      </Constant>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Database_Status_ObjectSet', @facet=N'IDatabaseMaintenanceFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Database_Status_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Database Status is Suspect, Inaccessible or Emergency', @condition_name=N'Database Status', @policy_category=N'Microsoft Best Practices: Database Configurations', @description=N'Database Status is Suspect, Inaccessible or in Emergency Mode.', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'Database_Status_ObjectSet'
Select @policy_id
GO

-- Are there Non-unique clustered indexes?
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Non-Unique Clustered Indexes', @description=N'Checks for Non-Unique Clustered indexes', @facet=N'Index', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>NE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Bool</TypeClass>
      <Name>IsClustered</Name>
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
    <OpType>NE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Bool</TypeClass>
      <Name>IsUnique</Name>
    </Attribute>
    <Function>
      <TypeClass>Bool</TypeClass>
      <FunctionType>True</FunctionType>
      <ReturnType>Bool</ReturnType>
      <Count>0</Count>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Non_Unique_Clustered_Indexes_ObjectSet', @facet=N'Index', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Non_Unique_Clustered_Indexes_ObjectSet', @type_skeleton=N'Server/Database/Table/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table', @level_name=N'Table', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Non_Unique_Clustered_Indexes_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedFunction/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction', @level_name=N'UserDefinedFunction', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Non_Unique_Clustered_Indexes_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedTableType/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedTableType/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedTableType', @level_name=N'UserDefinedTableType', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Non_Unique_Clustered_Indexes_ObjectSet', @type_skeleton=N'Server/Database/View/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View', @level_name=N'View', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Non-Unique Clustered Indexes', @condition_name=N'Non-Unique Clustered Indexes', @policy_category=N'Microsoft Best Practices: Database Design', @description=N'With few exceptions, every table should have a clustered index. Very few exceptions to this, such as Bulk Load, Staging or some types of Temporary tables.
When creating a clustering index, remember that uniqueness is maintained in key values. Therefore, if you don�t create UNIQUE clustered index, SQL Server will add a 4-byte hidden column to make it unique, the �uniquefier�.
Generally, an ideal candidate for a clustering key should be a unique, monotonically increasing and occasionally updated value.', @help_text=N'', @help_link=N'http://msdn.microsoft.com/en-us/library/ms177443.aspx', @schedule_uid=N'00000000-0000-0000-0000-000000000000', @execution_mode=0, @is_enabled=False, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Non_Unique_Clustered_Indexes_ObjectSet'
Select @policy_id
GO

-- Is Index Fill Factor below 80 pct?
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Fill Factor', @description=N'Checks for Fill Factor below 80 pct.', @facet=N'Index', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LT</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>FillFactor</Name>
  </Attribute>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>80</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'IX_Fill_Factor_ObjectSet', @facet=N'Index', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'IX_Fill_Factor_ObjectSet', @type_skeleton=N'Server/Database/Table/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table', @level_name=N'Table', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'IX_Fill_Factor_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedFunction/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction', @level_name=N'UserDefinedFunction', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'IX_Fill_Factor_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedTableType/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedTableType/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedTableType', @level_name=N'UserDefinedTableType', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'IX_Fill_Factor_ObjectSet', @type_skeleton=N'Server/Database/View/Index', @type=N'INDEX', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View', @level_name=N'View', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Index Fill Factor below 80 pct', @condition_name=N'Fill Factor', @policy_category=N'Microsoft Best Practices: Database Design', @description=N'Fill factor is used to determine how much free space is required for an index page. This is necessary in order to keep the index as compact as possible while as the same time preventing performance delays when splitting data to a new page after the current page fills up.
Generally, the correct fill factor will depend significantly on the amount and type of operations being performed on the table.
In an environment where most of the activity on a table is due to insert operations, use a lower fill factor to prevent the fragmentation and increased I/O associated with page splits.
In an environment where most of the activity is due to select operations, use a higher fill factor.', @help_text=N'', @help_link=N'http://msdn2.microsoft.com/en-us/library/ms191005.aspx', @schedule_uid=N'00000000-0000-0000-0000-000000000000', @execution_mode=0, @is_enabled=False, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'IX_Fill_Factor_ObjectSet'
Select @policy_id
GO

-- Log growth
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Log is 1GB or Larger', @description=N'Confirms that the log file size is larger than 1 GB when percent grow is configured.', @facet=N'LogFile', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>Size</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>1024</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>GrowthType</Name>
    </Attribute>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>Enum</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Microsoft.SqlServer.Management.Smo.FileGrowthType</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Percent</Value>
      </Constant>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Log_Growth_ObjectSet', @facet=N'LogFile', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Log_Growth_ObjectSet', @type_skeleton=N'Server/Database/LogFile', @type=N'LOGFILE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/LogFile', @level_name=N'LogFile', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Log Growth for SQL Server', @condition_name=N'Log is 1GB or Larger', @policy_category=N'Microsoft Best Practices: Performance', @description=N'When setting autogrow for Data and Log files, keep in mind that it might be preferred to set it in Megabytes instead of Percentage, to allow better control on the growth ratio, as percentage is an ever-growing amount. This is even more critical when Instant File Initialization is not in use, as long I/O might become a bottleneck. Keep in mind that transaction logs cannot leverage Instant File Initialization, so extended log growth times are especially critical. As a rule, do not set any AUTOGROW value above 1024MB.
Also, if you grow your database by small increments (or if you grow it and then shrink it) you can end up with disk fragmentation. Disk fragmentation can cause performance issues in some circumstances.
Use ALTER DATABASE command to manage the auto growth settings. Set the FILEGROWTH (autogrow) value to a fixed size to avoid escalating performance problems.', @help_link=N'http://support.microsoft.com/kb/315512', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'Log_Growth_ObjectSet'
Select @policy_id
GO

-- Are there tables with non-clustered IXs but no clustered IX?
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Tables with Indexes and none is Clustered', @description=N'Checks for Tables with Non-clustered Indexes and no Clustered Index.', @facet=N'Table', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Bool</TypeClass>
      <Name>HasClusteredIndex</Name>
    </Attribute>
    <Function>
      <TypeClass>Bool</TypeClass>
      <FunctionType>True</FunctionType>
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
      <Name>HasIndex</Name>
    </Attribute>
    <Function>
      <TypeClass>Bool</TypeClass>
      <FunctionType>True</FunctionType>
      <ReturnType>Bool</ReturnType>
      <Count>0</Count>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Tbl_No_CLIX_ObjectSeT', @facet=N'Table', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Tbl_No_CLIX_ObjectSeT', @type_skeleton=N'Server/Database/Table', @type=N'TABLE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table', @level_name=N'Table', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Tables that do not have a clustered index, although non-clustered indexes exist', @condition_name=N'Tables with Indexes and none is Clustered', @policy_category=N'Microsoft Best Practices: Database Design', @description=N'In most situations, each table in the database should have a clustered index defined for it. Without a clustered index, the heap will not be defragmented as part of your regular index rebuild or reorganization process. As a result, query performance could suffer.
Clustered indexes define the physical order of the rows in a table, with the leaf level of the clustered index containing the actual data rows for the table. When selecting a clustered index key, select columns that have a high cardinality, are frequently referenced in query criteria, and are used within range queries.
Evaluate your application query activity against the heap table. In addition, define the best column candidate for the index key and create the clustered index.', @help_link=N'http://msdn2.microsoft.com/en-us/library/ms191195.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'Tbl_No_CLIX_ObjectSeT'
Select @policy_id
GO

-- VLFs
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Virtual Log Files', @description=N'Checks the number of Virtual Log Files.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LE</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>CREATE TABLE #pbm_log_info (recoveryunitid int NULL, fileid tinyint, file_size bigint, start_offset bigint, FSeqNo int, [status] tinyint, parity tinyint, create_lsn numeric(25,0))&lt;?char 13?&gt;
IF CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) &lt; 11&lt;?char 13?&gt;
BEGIN&lt;?char 13?&gt;
	INSERT INTO #pbm_log_info (fileid, file_size, start_offset, FSeqNo, [status], parity, create_lsn)&lt;?char 13?&gt;
	EXEC sp_executesql ''''DBCC LOGINFO WITH NO_INFOMSGS''''&lt;?char 13?&gt;
END&lt;?char 13?&gt;
ELSE&lt;?char 13?&gt;
BEGIN&lt;?char 13?&gt;
	INSERT INTO #pbm_log_info (recoveryunitid, fileid, file_size, start_offset, FSeqNo, [status], parity, create_lsn)&lt;?char 13?&gt;
	EXEC sp_executesql ''''DBCC LOGINFO WITH NO_INFOMSGS''''&lt;?char 13?&gt;
END&lt;?char 13?&gt;
SELECT COUNT(*) FROM #pbm_log_info&lt;?char 13?&gt;
DROP TABLE #pbm_log_info</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>100</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'HighVLFs_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'HighVLFs_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'High VLFs', @condition_name=N'Virtual Log Files', @policy_category=N'Microsoft Best Practices: Maintenance', @description=N'The transaction log files are internally divided into sections called Virtual Log Files (VLFs) and the more transaction log file experiences the fragmentation, the more the VLFs created. Several VLFs are generated if the transaction log file is created by small initial size and small growth increments. Once the transaction log file builds more than 100 VLFs, you may start noticing the performance issues with the operations that use the transaction log file such as log reads for transactional replication, rollback, log backups and database recovery etc.
Create the transaction log file with an appropriate initial size, anticipate the future needs and set the auto growth to an adequate size. While sizing the transaction log file consider the factors like transaction size (long-running transactions cannot be cleared from the log until they complete) and log backup frequency (since this is what removes the inactive portion of the log).', @help_text=N'', @help_link=N'http://blogs.msdn.com/b/blogdoezequiel/archive/2010/05/31/sql-server-and-log-file-usage.aspx', @is_enabled=False, @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'HighVLFs_ObjectSet'
Select @policy_id
GO

-- Enterprise SKU
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'SQL Server Version 2005 or a Later Version and Enterprise Edition', @description=N'Confirms that the version of SQL Server is 2005 or a later version and that the SKU is Enterprise or Developer Edition.', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>VersionMajor</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>9</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>EngineEdition</Name>
    </Attribute>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>Enum</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Microsoft.SqlServer.Management.Smo.Edition</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>EnterpriseOrDeveloper</Value>
      </Constant>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Enterprise Features usage', @description=N'Checks for Enterprise features usage per database.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>SELECT COUNT(feature_name) FROM sys.dm_db_persisted_sku_features (NOLOCK)</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>0</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Enterprise_Features_Usage_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Enterprise_Features_Usage_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Enterprise Features Usage', @condition_name=N'Enterprise Features usage', @policy_category=N'Microsoft Best Practices: Database Design', @description=N'Some features of the SQL Server Database Engine change the way that Database Engine stores information in the database files. These features are restricted to specific editions of SQL Server. A database that contains these features cannot be moved to an edition of SQL Server that does not support them.', @help_link=N'http://msdn.microsoft.com/en-us/library/cc645993.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version and Enterprise Edition', @object_set=N'Enterprise_Features_Usage_ObjectSet'
Select @policy_id
GO

-- Maxmem not default
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Maximum Server Memory not Default', @description=N'Checks if the server Maximum memory setting is not default.', @facet=N'IServerConfigurationFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LT</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>MaxServerMemory</Name>
  </Attribute>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>2147483647</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Serve_Max_ Memory_must_not_be_Default_ObjectSet', @facet=N'IServerConfigurationFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Serve_Max_ Memory_must_not_be_Default_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server Max Server Memory must not be set at Default', @condition_name=N'Maximum Server Memory not Default', @policy_category=N'Microsoft Best Practices: Server Configuration', @description=N'This setting configures the maximum amount of buffer pool memory for the Microsoft SQL Server instance. The default setting is 2,147,483,647. If you set this value too high, a single instance of SQL Server might have to compete for memory with other SQL instances hosted on the node or computer. However, setting this value too low could cause significant memory pressure and performance problems.
Consider capping this configuration for each running SQL instance. Monitor overall consumption of the SQL Server process in order to determine memory requirements.', @help_link=N'http://msdn2.microsoft.com/en-us/library/ms178067.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'SQL_Serve_Max_ Memory_must_not_be_Default_ObjectSet'
Select @policy_id
GO

-- Maxmem should not be fixed
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Maximum Server Memory not Fixed', @description=N'Checks if the server Maximum memory setting is not fixed.', @facet=N'IServerConfigurationFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>GT</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>MaxServerMemory</Name>
  </Attribute>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>MinServerMemory</Name>
  </Attribute>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Server_Max_Memory_should_not_be_fixed_ObjectSet', @facet=N'IServerConfigurationFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Server_Max_Memory_should_not_be_fixed_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server Max Server Memory should not be fixed', @condition_name=N'Maximum Server Memory not Fixed', @policy_category=N'Microsoft Best Practices: Server Configuration', @description=N'In a failover cluster configuration, when several instances can exist concurrently in the same node, set the min_server_memory parameter instead of max_server_memory for the purpose of reserving memory for an instance. In this scenario the max_server_memory is used mainly to prevent memory exhaustion in the OS.
From SQL 2005 up, with new memory management algorithms, there is no need to set aside xx amount of memory preemptively to accommodate a failover. Because the instances will respond to memory pressure, they will in fact adapt their memory usage to cope with pressure. This means that for the several instances sharing a failover cluster, the max_server_memory can be set to somewhat overlap.', @help_link=N'http://msdn.microsoft.com/en-us/library/ms180797.aspx', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'SQL_Server_Max_Memory_should_not_be_fixed_ObjectSet'
Select @policy_id
GO

-- DB Compat level same as engine?
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Compatibility Level', @description=N'Checks if Database Compatibility level for each database is set to the same version as the SQL Server Engine.', @facet=N'IDatabaseOptions', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>SELECT CONVERT(int, (@@microsoftversion / 0x1000000) &amp; 0xff) * 10</Value>
    </Constant>
  </Function>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>CompatibilityLevel</Name>
  </Attribute>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Compatibility_Level_is_Optimal_ObjectSet', @facet=N'IDatabaseOptions', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Compatibility_Level_is_Optimal_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'User or Model', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Compatibility Level is Optimal', @condition_name=N'Compatibility Level', @policy_category=N'Microsoft Best Practices: Database Configurations', @description=N'Database Compatibility level for each database should be set to the same version as the SQL Server Engine, unless need of backward compatibility dictates otherwise, and always as a temporary fix while converting the applications to work properly. This has tremendous impact on database performance on a given SQL Server.', @help_text=N'', @help_link=N'http://msdn.microsoft.com/en-us/library/bb510680.aspx', @is_enabled=False, @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'Compatibility_Level_is_Optimal_ObjectSet'
Select @policy_id
GO

-- Next is needed for all 3 TempDB policies
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'TempDB', @description=N'Evaluates only on TempDB.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>tempdb</Value>
  </Constant>
</Operator>', @is_name_condition=1, @obj_name=N'tempdb', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

-- Tempdb file config is optimal
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'TempDB Number of Files is Optimal', @description=N'Checks if TempDB Data Files to Online Schedulers is optimal. Number of Data Files is between 4 and 8, or if higher then at least half the online schedulers, and also if the number of Data Files is multiple of 4.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>DECLARE @tdb_files int, @online_count int SELECT @tdb_files = COUNT(physical_name) FROM sys.master_files (NOLOCK) WHERE database_id = 2 AND [type] = 0; SELECT @online_count = COUNT(cpu_id) FROM sys.dm_os_schedulers WHERE is_online = 1 AND scheduler_id &lt; 255 AND parent_node_id &lt; 64; SELECT CASE WHEN (@tdb_files &gt;= 4 AND @tdb_files &lt;= 8 AND @tdb_files % 4 = 0) OR (@tdb_files &gt;= (@online_count / 2) AND @tdb_files &gt;= 8 AND @tdb_files % 4 = 0) THEN 0 ELSE 1 END</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>0</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'TempDB_Configuration_is_Optimal_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'TempDB_Configuration_is_Optimal_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'TempDB', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'TempDB Data File Configuration is Optimal', @condition_name=N'TempDB Number of Files is Optimal', @policy_category=N'Microsoft Best Practices: Performance', @description=N'Having multiple TempDB data files can reduce contention and improve performance on active systems. This is because there will be one or more SGAM pages for each file, the main point of contention for mixed allocations. If there is a need to increase above the initial 8 files, do so by multiples of 4 files.
Dividing TempDB into multiple data files of equal size provides a high degree of parallel efficiency in operations that use TempDB. These multiple files do not necessarily need to be on different disks or spindles unless you are also encountering I/O bottlenecks as well.
One disadvantage of having too many TempDB files is that every object in TempDB will have multiple IAM pages. In addition, there will be more switching costs as objects are accessed as well as more managing overhead. On very large systems, 8 TempDB data files may be sufficient, but reconsider this based on the workload. If there is a need to increase above the initial 8 files, do so by multiples of 4 files.', @help_text=N'', @help_link=N'http://support.microsoft.com/kb/2154845/en-us', @is_enabled=False, @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'TempDB_Configuration_is_Optimal_ObjectSet'
Select @policy_id
GO

-- Tempdb files sizes match
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'TempDB Data File Sizes Match', @description=N'Checks if TempDB Data File sizes match, when more than 1 Data File exists.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>DECLARE @filecnt int SELECT @filecnt = COUNT(physical_name) FROM sys.master_files (NOLOCK) WHERE database_id = 2 AND type = 0 IF @filecnt &gt; 1 BEGIN SELECT COUNT(DISTINCT size) FROM sys.master_files WHERE database_id = 2 AND type = 0 END ELSE BEGIN SELECT 1 END</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>1</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO
Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'TempDB_File_Sizes_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'TempDB_File_Sizes_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'TempDB', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'TempDB Data File Sizes Match', @condition_name=N'TempDB Data File Sizes Match', @policy_category=N'Microsoft Best Practices: Performance', @description=N'Dividing TempDB into multiple data files of equal size provides a high degree of parallel efficiency in operations that use TempDB. These multiple files do not necessarily need to be on different disks or spindles unless you are also encountering I/O bottlenecks as well.
Be aware that if one of the data files is larger than the others, this mechanism will not be effective, so check if growth via AUTOGROW has happened on one file and broke the proportional fill.', @help_text=N'', @help_link=N'http://msdn2.microsoft.com/en-us/library/ms175527.aspx', @is_enabled=False, @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'TempDB_File_Sizes_ObjectSet'
Select @policy_id
GO

-- Tempdb files multiple 4
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'TempDB Data File number is multiple of 4', @description=N'Checks if TempDB Data Files exist in multiples of 4, when more than 1 Data File exists.', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>DECLARE @filecnt int SELECT @filecnt = COUNT(physical_name) FROM sys.master_files (NOLOCK) WHERE database_id = 2 AND type = 0 IF @filecnt > 1 BEGIN SELECT @filecnt % 4 END ELSE BEGIN SELECT 0 END</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>0</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'TempDB_Data_File_number_multiple_of_4_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'TempDB_Data_File_number_multiple_of_4_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'TempDB', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'TempDB Data File number is multiple of 4', @condition_name=N'TempDB Data File number is multiple of 4', @policy_category=N'Microsoft Best Practices: Performance', @description=N'Dividing TempDB into multiple data files of equal size provides a high degree of parallel efficiency in operations that use TempDB. These multiple files do not necessarily need to be on different disks or spindles unless you are also encountering I/O bottlenecks as well.
Having multiple TempDB data files can reduce contention and improve performance on active systems. This is because there will be one or more SGAM pages for each file, the main point of contention for mixed allocations. If there is a need to increase above the initial 8 files, do so by multiples of 4 files.', @help_text=N'', @help_link=N'http://support.microsoft.com/kb/2154845/en-us', @is_enabled=False, @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'TempDB_Data_File_number_multiple_of_4_ObjectSet'
Select @policy_id
GO

-- Fix policy for SQL 2000 only. New is created for SQL 2005 and above
EXEC msdb.dbo.sp_syspolicy_rename_policy @name = N'SQL Server Max Degree of Parallelism', @new_name = N'SQL Server Max Degree of Parallelism for SQL Server 2000';
GO
EXEC msdb.dbo.sp_syspolicy_update_policy @name = N'SQL Server Max Degree of Parallelism for SQL Server 2000', @root_condition_name=N'SQL Server Version 2000', @policy_category=N'Microsoft Best Practices: Server Configuration'
GO
EXEC msdb.dbo.sp_syspolicy_rename_condition @name = N'Maximum Degree of Parallelism Optimized', @new_name = N'Maximum Degree of Parallelism Optimized for SQL 2000';
GO

-- MaxDOP for 2005 and above
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Maximum Degree of Parallelism Optimized for SQL Server 2005 and above', @description=N'Confirms that the maximum degree of parallelism is less than 8 or no more then available CPUs per NUMA node. 8 is optimal.', @facet=N'IServerPerformanceFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>OR</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>LE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>MaxDegreeOfParallelism</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>8</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>LE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>MaxDegreeOfParallelism</Name>
    </Attribute>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>ExecuteSql</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Numeric</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>SELECT COUNT(cpu_id)/COUNT(DISTINCT parent_node_id) FROM sys.dm_os_schedulers WHERE scheduler_id &lt; 255 AND parent_node_id &lt; 64</Value>
      </Constant>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'SQL_Server_Maxdop_ObjectSet', @facet=N'IServerPerformanceFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'SQL_Server_Maxdop_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'SQL Server Max Degree of Parallelism', @condition_name=N'Maximum Degree of Parallelism Optimized for SQL Server 2005 and above', @policy_category=N'Microsoft Best Practices: Server Configuration', @description=N'Checks the max degree of parallelism option for the optimal value to avoid unwanted resource consumption and performance degradation. The recommended value of this option is 8 or less, when that value is also preferably equal nor less than the number of schedulers per NUMA node. Setting this option to a larger value often results in unwanted resource consumption and performance degradation.', @help_link=N'http://go.microsoft.com/fwlink/?LinkId=116335', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'SQL Server Version 2005 or a Later Version', @object_set=N'SQL_Server_Maxdop_ObjectSet'
Select @policy_id
GO

-- Delete "File Growth for SQL Server 2000" and implement next one for all versions
EXEC msdb.dbo.sp_syspolicy_delete_policy @name = N'File Growth for SQL Server 2000'
GO

-- Added only when IsPercent = 1
EXEC msdb.dbo.sp_syspolicy_update_condition @name=N'File is 1GB or Larger', @description=N'Confirms that the file size is larger than 1 GB.', @facet=N'DataFile', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>Size</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>1024</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>GrowthType</Name>
    </Attribute>
    <Function>
      <TypeClass>Numeric</TypeClass>
      <FunctionType>Enum</FunctionType>
      <ReturnType>Numeric</ReturnType>
      <Count>2</Count>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Microsoft.SqlServer.Management.Smo.FileGrowthType</Value>
      </Constant>
      <Constant>
        <TypeClass>String</TypeClass>
        <ObjType>System.String</ObjType>
        <Value>Percent</Value>
      </Constant>
    </Function>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N''
GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'File_Growth_for_SQL_Server_ObjectSet', @facet=N'DataFile', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'File_Growth_for_SQL_Server_ObjectSet', @type_skeleton=N'Server/Database/FileGroup/File', @type=N'FILE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/FileGroup/File', @level_name=N'File', @condition_name=N'File is 1GB or Larger', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/FileGroup', @level_name=N'FileGroup', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'File Growth for SQL Server', @condition_name=N'Growth Type Not Percent', @policy_category=N'Microsoft Best Practices: Performance', @description=N'When setting autogrow for Data and Log files, keep in mind that it might be preferred to set it in Megabytes instead of Percentage, to allow better control on the growth ratio, as percentage is an ever-growing amount. This is even more critical when Instant File Initialization is not in use, as long I/O might become a bottleneck. Keep in mind that transaction logs cannot leverage Instant File Initialization, so extended log growth times are especially critical. As a rule, do not set any AUTOGROW value above 1024MB.
Also, if you grow your database by small increments (or if you grow it and then shrink it) you can end up with disk fragmentation. Disk fragmentation can cause performance issues in some circumstances.
Use ALTER DATABASE command to manage the auto growth settings. Set the FILEGROWTH (autogrow) value to a fixed size to avoid escalating performance problems.', @help_text=N'', @help_link=N'http://support.microsoft.com/kb/315512', @is_enabled=False, @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'File_Growth_for_SQL_Server_ObjectSet'
Select @policy_id
GO