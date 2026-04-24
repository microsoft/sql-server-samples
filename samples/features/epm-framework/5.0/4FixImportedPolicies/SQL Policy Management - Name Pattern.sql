/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute
the object code form of the Sample Code, provided that You agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indentify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits,
including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

Please note: None of the conditions outlined in the disclaimer above will supersede the terms and
conditions contained within the Premier Customer Services Description.

*/

use msdb
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--POLICY CATEGORY: Name Pattern
DECLARE @policy_category_id int;

SELECT @policy_category_id = policy_category_id FROM dbo.syspolicy_policy_categories where name = N'Name_Pattern'

IF (@policy_category_id IS NULL)
BEGIN
	EXEC msdb.dbo.sp_syspolicy_add_policy_category
	  @name = N'Name_Pattern'
	, @mandate_database_subscriptions = 1
	, @policy_category_id = @policy_category_id OUTPUT;
END

SELECT @policy_category_id as NEW_policy_category_id

GO
/*
--------------------------------------------------------------------------------------------------------------------------------------------
--DELETE ALL POLICIES
DECLARE @policy_id INT

DECLARE  CURSOR_POLICIES_TO_DELETE CURSOR FAST_FORWARD FOR
	SELECT policy_id FROM dbo.syspolicy_policies P
	INNER JOIN dbo.syspolicy_policy_categories PC
		ON P.policy_category_id = PC.policy_category_id
	WHERE PC.[name] = N'Name_Pattern'

OPEN CURSOR_POLICIES_TO_DELETE

FETCH NEXT FROM CURSOR_POLICIES_TO_DELETE
INTO @policy_id

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC msdb.dbo.sp_syspolicy_delete_policy @policy_id=@policy_id

    FETCH NEXT FROM CURSOR_POLICIES_TO_DELETE
    INTO @policy_id
END
CLOSE CURSOR_POLICIES_TO_DELETE
DEALLOCATE CURSOR_POLICIES_TO_DELETE

GO


--------------------------------------------------------------------------------------------------------------------------------------------
--DELETE ALL OBJECTSETS AND TARGET SET
--SELECT * FROM dbo.syspolicy_object_sets where is_system = 0
DECLARE @object_set_id INT
DECLARE @target_set_id INT

DECLARE  CURSOR_OBJECTS_SETS_TO_DELETE CURSOR FAST_FORWARD FOR
	SELECT object_set_id FROM dbo.syspolicy_object_sets where is_system = 0

OPEN CURSOR_OBJECTS_SETS_TO_DELETE

FETCH NEXT FROM CURSOR_OBJECTS_SETS_TO_DELETE
INTO @object_set_id

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		
		EXEC msdb.dbo.sp_syspolicy_delete_object_set @object_set_id=@object_set_id
		SELECT 'DELETE @object_set_id', @object_set_id

		SELECT @target_set_id=target_set_id FROM dbo.syspolicy_target_sets where @object_set_id=@object_set_id
		
		EXEC msdb.dbo.sp_syspolicy_delete_target_set @target_set_id=@target_set_id
		SELECT 'DELETE @target_set_id', @target_set_id
		

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

    FETCH NEXT FROM CURSOR_OBJECTS_SETS_TO_DELETE
    INTO @object_set_id
END
CLOSE CURSOR_OBJECTS_SETS_TO_DELETE
DEALLOCATE CURSOR_OBJECTS_SETS_TO_DELETE

GO


--------------------------------------------------------------------------------------------------------------------------------------------
--DELETE ALL CONDITIONS

DECLARE @condition_id INT

DECLARE  CURSOR_CONDITIONS_TO_DELETE CURSOR FAST_FORWARD FOR
	SELECT condition_id FROM dbo.syspolicy_conditions where is_system = 0

OPEN CURSOR_CONDITIONS_TO_DELETE

FETCH NEXT FROM CURSOR_CONDITIONS_TO_DELETE
INTO @condition_id

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		EXEC msdb.dbo.sp_syspolicy_delete_condition @condition_id=@condition_id
		SELECT 'DELETE @condition_id', @condition_id
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

    FETCH NEXT FROM CURSOR_CONDITIONS_TO_DELETE
    INTO @condition_id
END
CLOSE CURSOR_CONDITIONS_TO_DELETE
DEALLOCATE CURSOR_CONDITIONS_TO_DELETE

GO
*/





--------------------------------------------------------------------------------------------------------------------------------------------
--Only User DB
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Only User DB', @description=N'', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>OR</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>GT</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>ID</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>4</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>EQ</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Bool</TypeClass>
      <Name>IsSystemObject</Name>
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






--------------------------------------------------------------------------------------------------------------------------------------------
--DB Name Pattern

Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'DB Name Pattern', @description=N'', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>___[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'___[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id as [@condition_id]

GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'DB Name Pattern_ObjectSet', @facet=N'Database', @object_set_id=@object_set_id OUTPUT
Select @object_set_id
Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'DB Name Pattern_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0
GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'DB Name Pattern', @condition_name=N'DB Name Pattern', @policy_category=N'Name_Pattern', @description=N'', @help_text=N'', @help_link=N'', @schedule_uid=N'00000000-0000-0000-0000-000000000000', @execution_mode=0, @is_enabled=False, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'DB Name Pattern_ObjectSet'
Select @policy_id
GO



--------------------------------------------------------------------------------------------------------------------------------------------
--Table Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Table Name Pattern', @description=N'', @facet=N'Table', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>tbl[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'tbl[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id

GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Table Name Pattern_ObjectSet', @facet=N'Table', @object_set_id=@object_set_id OUTPUT
Select @object_set_id
Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Table Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/Table', @type=N'TABLE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table', @level_name=N'Table', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0
GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Table Name Pattern', @condition_name=N'Table Name Pattern', @policy_category=N'Name_Pattern', @description=N'', @help_text=N'', @help_link=N'', @schedule_uid=N'00000000-0000-0000-0000-000000000000', @execution_mode=0, @is_enabled=False, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Table Name Pattern_ObjectSet'
Select @policy_id
GO




--------------------------------------------------------------------------------------------------------------------------------------------
--Index Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Index Name Pattern', @description=N'', @facet=N'Index', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>OR</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>OR</OpType>
    <Count>2</Count>
    <Operator>
      <TypeClass>Bool</TypeClass>
      <OpType>OR</OpType>
      <Count>2</Count>
      <Operator>
        <TypeClass>Bool</TypeClass>
        <OpType>OR</OpType>
        <Count>2</Count>
        <Operator>
          <TypeClass>Bool</TypeClass>
          <OpType>LIKE</OpType>
          <Count>2</Count>
          <Attribute>
            <TypeClass>String</TypeClass>
            <Name>Name</Name>
          </Attribute>
          <Constant>
            <TypeClass>String</TypeClass>
            <ObjType>System.String</ObjType>
            <Value>IX[_]%</Value>
          </Constant>
        </Operator>
        <Group>
          <TypeClass>Bool</TypeClass>
          <Count>1</Count>
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
                  <Name>IsClustered</Name>
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
                  <Name>IsUnique</Name>
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
              <OpType>LIKE</OpType>
              <Count>2</Count>
              <Attribute>
                <TypeClass>String</TypeClass>
                <Name>Name</Name>
              </Attribute>
              <Constant>
                <TypeClass>String</TypeClass>
                <ObjType>System.String</ObjType>
                <Value>CIX[_]%</Value>
              </Constant>
            </Operator>
          </Operator>
        </Group>
      </Operator>
      <Group>
        <TypeClass>Bool</TypeClass>
        <Count>1</Count>
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
              <Name>IsXmlIndex</Name>
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
            <OpType>LIKE</OpType>
            <Count>2</Count>
            <Attribute>
              <TypeClass>String</TypeClass>
              <Name>Name</Name>
            </Attribute>
            <Constant>
              <TypeClass>String</TypeClass>
              <ObjType>System.String</ObjType>
              <Value>XML[_]IX[_]%</Value>
            </Constant>
          </Operator>
        </Operator>
      </Group>
    </Operator>
    <Group>
      <TypeClass>Bool</TypeClass>
      <Count>1</Count>
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
              <Name>IsUnique</Name>
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
              <Name>IsClustered</Name>
            </Attribute>
            <Function>
              <TypeClass>Bool</TypeClass>
              <FunctionType>False</FunctionType>
              <ReturnType>Bool</ReturnType>
              <Count>0</Count>
            </Function>
          </Operator>
        </Operator>
        <Group>
          <TypeClass>Bool</TypeClass>
          <Count>1</Count>
          <Operator>
            <TypeClass>Bool</TypeClass>
            <OpType>OR</OpType>
            <Count>2</Count>
            <Operator>
              <TypeClass>Bool</TypeClass>
              <OpType>LIKE</OpType>
              <Count>2</Count>
              <Attribute>
                <TypeClass>String</TypeClass>
                <Name>Name</Name>
              </Attribute>
              <Constant>
                <TypeClass>String</TypeClass>
                <ObjType>System.String</ObjType>
                <Value>PK[_]%</Value>
              </Constant>
            </Operator>
            <Operator>
              <TypeClass>Bool</TypeClass>
              <OpType>LIKE</OpType>
              <Count>2</Count>
              <Attribute>
                <TypeClass>String</TypeClass>
                <Name>Name</Name>
              </Attribute>
              <Constant>
                <TypeClass>String</TypeClass>
                <ObjType>System.String</ObjType>
                <Value>UIX[_]%</Value>
              </Constant>
            </Operator>
          </Operator>
        </Group>
      </Operator>
    </Group>
  </Operator>
  <Group>
    <TypeClass>Bool</TypeClass>
    <Count>1</Count>
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
            <Name>IsClustered</Name>
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
            <Name>IsUnique</Name>
          </Attribute>
          <Function>
            <TypeClass>Bool</TypeClass>
            <FunctionType>True</FunctionType>
            <ReturnType>Bool</ReturnType>
            <Count>0</Count>
          </Function>
        </Operator>
      </Operator>
      <Group>
        <TypeClass>Bool</TypeClass>
        <Count>1</Count>
        <Operator>
          <TypeClass>Bool</TypeClass>
          <OpType>OR</OpType>
          <Count>2</Count>
          <Operator>
            <TypeClass>Bool</TypeClass>
            <OpType>LIKE</OpType>
            <Count>2</Count>
            <Attribute>
              <TypeClass>String</TypeClass>
              <Name>Name</Name>
            </Attribute>
            <Constant>
              <TypeClass>String</TypeClass>
              <ObjType>System.String</ObjType>
              <Value>PK[_]%</Value>
            </Constant>
          </Operator>
          <Operator>
            <TypeClass>Bool</TypeClass>
            <OpType>LIKE</OpType>
            <Count>2</Count>
            <Attribute>
              <TypeClass>String</TypeClass>
              <Name>Name</Name>
            </Attribute>
            <Constant>
              <TypeClass>String</TypeClass>
              <ObjType>System.String</ObjType>
              <Value>CUIX[_]%</Value>
            </Constant>
          </Operator>
        </Operator>
      </Group>
    </Operator>
  </Group>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO








Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Index Name Pattern_ObjectSet', @facet=N'Index', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Index Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/Table/Index', @type=N'INDEX', @enabled=False, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table', @level_name=N'Table', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Index Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedFunction/Index', @type=N'INDEX', @enabled=False, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction', @level_name=N'UserDefinedFunction', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Index Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedTableType/Index', @type=N'INDEX', @enabled=False, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedTableType/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedTableType', @level_name=N'UserDefinedTableType', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Index Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/View/Index', @type=N'INDEX', @enabled=False, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View/Index', @level_name=N'Index', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View', @level_name=N'View', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0


GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Index Name Pattern', @condition_name=N'Index Name Pattern', @policy_category=N'Name_Pattern', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'Index Name Pattern_ObjectSet'
Select @policy_id


GO




--------------------------------------------------------------------------------------------------------------------------------------------
--CView Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'View Name Pattern', @description=N'', @facet=N'View', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>vw[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'vw[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id

GO
Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'View Name Pattern_ObjectSet', @facet=N'View', @object_set_id=@object_set_id OUTPUT
Select @object_set_id
Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'View Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/View', @type=N'VIEW', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View', @level_name=N'View', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0

GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'View Name Pattern', @condition_name=N'View Name Pattern', @policy_category=N'Name_Pattern', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'View Name Pattern_ObjectSet'
Select @policy_id


GO



--------------------------------------------------------------------------------------------------------------------------------------------
--Stored Procedures Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Stored Procedures Name Pattern', @description=N'', @facet=N'StoredProcedure', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>AND</OpType>
  <Count>2</Count>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>LIKE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>String</TypeClass>
      <Name>Name</Name>
    </Attribute>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>sp%</Value>
    </Constant>
  </Operator>
  <Operator>
    <TypeClass>Bool</TypeClass>
    <OpType>NOT_LIKE</OpType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>String</TypeClass>
      <Name>Name</Name>
    </Attribute>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>sp[_]%</Value>
    </Constant>
  </Operator>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO




Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Stored Procedures Name Pattern_ObjectSet', @facet=N'StoredProcedure', @object_set_id=@object_set_id OUTPUT
Select @object_set_id
Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Stored Procedures Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/StoredProcedure', @type=N'PROCEDURE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/StoredProcedure', @level_name=N'StoredProcedure', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0
GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Stored Procedures Name Pattern', @condition_name=N'Stored Procedures Name Pattern', @policy_category=N'Name_Pattern', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Stored Procedures Name Pattern_ObjectSet'
Select @policy_id
GO



--------------------------------------------------------------------------------------------------------------------------------------------
--UserFunction
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'UserFunction', @description=N'', @facet=N'UserDefinedFunction', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>fn[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'fn[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id

GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'UserFunction_ObjectSet', @facet=N'UserDefinedFunction', @object_set_id=@object_set_id OUTPUT
Select @object_set_id
Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'UserFunction_ObjectSet', @type_skeleton=N'Server/Database/UserDefinedFunction', @type=N'FUNCTION', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/UserDefinedFunction', @level_name=N'UserDefinedFunction', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0
GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'UserFunction', @condition_name=N'UserFunction', @policy_category=N'Name_Pattern', @execution_mode=0, @policy_id=@policy_id OUTPUT, @object_set=N'UserFunction_ObjectSet'
Select @policy_id
GO



--------------------------------------------------------------------------------------------------------------------------------------------
--Trigger Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Trigger Name Pattern', @description=N'', @facet=N'Trigger', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>OR</OpType>
  <Count>2</Count>
  <Group>
    <TypeClass>Bool</TypeClass>
    <Count>1</Count>
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
          <Name>InsteadOf</Name>
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
        <OpType>LIKE</OpType>
        <Count>2</Count>
        <Attribute>
          <TypeClass>String</TypeClass>
          <Name>Name</Name>
        </Attribute>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>TRI[_]%</Value>
        </Constant>
      </Operator>
    </Operator>
  </Group>
  <Group>
    <TypeClass>Bool</TypeClass>
    <Count>1</Count>
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
          <Name>InsteadOf</Name>
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
        <OpType>LIKE</OpType>
        <Count>2</Count>
        <Attribute>
          <TypeClass>String</TypeClass>
          <Name>Name</Name>
        </Attribute>
        <Constant>
          <TypeClass>String</TypeClass>
          <ObjType>System.String</ObjType>
          <Value>TRA[_]%</Value>
        </Constant>
      </Operator>
    </Operator>
  </Group>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO


Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Trigger Name Pattern_ObjectSet', @facet=N'Trigger', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Trigger Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/Table/Trigger', @type=N'TRIGGER', @enabled=False, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table/Trigger', @level_name=N'Trigger', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Table', @level_name=N'Table', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0

EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Trigger Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/View/Trigger', @type=N'TRIGGER', @enabled=False, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View/Trigger', @level_name=N'Trigger', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/View', @level_name=N'View', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0


GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Trigger Name Pattern', @condition_name=N'Trigger Name Pattern', @policy_category=N'Name_Pattern', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Trigger Name Pattern_ObjectSet'
Select @policy_id


GO



--------------------------------------------------------------------------------------------------------------------------------------------
--Sequence Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Sequence Name Pattern', @description=N'', @facet=N'Sequence', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>SEQ[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'SEQ[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id

GO

Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Sequence Name Pattern_ObjectSet', @facet=N'Sequence', @object_set_id=@object_set_id OUTPUT
Select @object_set_id
Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Sequence Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/Sequence', @type=N'SEQUENCE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/Sequence', @level_name=N'Sequence', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'', @target_set_level_id=0
GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Sequence Name Pattern', @condition_name=N'Sequence Name Pattern', @execution_mode=0, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Sequence Name Pattern_ObjectSet', @policy_category=N'Name_Pattern'
Select @policy_id
GO




--------------------------------------------------------------------------------------------------------------------------------------------
--Partition Function Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Partition Function Name Pattern', @description=N'', @facet=N'PartitionFunction', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>PF[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'PF[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id

GO



Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Partition Function Name Pattern_ObjectSet', @facet=N'PartitionFunction', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Partition Function Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/PartitionFunction', @type=N'PARTITIONFUNCTION', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/PartitionFunction', @level_name=N'PartitionFunction', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0
GO
Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Partition Function Name Pattern', @condition_name=N'Partition Function Name Pattern', @policy_category=N'Name_Pattern', @description=N'', @help_text=N'', @help_link=N'', @schedule_uid=N'00000000-0000-0000-0000-000000000000', @execution_mode=0, @is_enabled=False, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Partition Function Name Pattern_ObjectSet'
Select @policy_id
GO


--------------------------------------------------------------------------------------------------------------------------------------------
--Partition Scheme Name Pattern
Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Partition Scheme Name Pattern', @description=N'', @facet=N'PartitionScheme', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LIKE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>String</TypeClass>
    <Name>Name</Name>
  </Attribute>
  <Constant>
    <TypeClass>String</TypeClass>
    <ObjType>System.String</ObjType>
    <Value>PS[_]%</Value>
  </Constant>
</Operator>', @is_name_condition=2, @obj_name=N'PS[_]%', @condition_id=@condition_id OUTPUT
Select @condition_id

GO



Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Partition Scheme Name Pattern_ObjectSet', @facet=N'PartitionScheme', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Partition Scheme Name Pattern_ObjectSet', @type_skeleton=N'Server/Database/PartitionScheme', @type=N'PARTITIONSCHEME', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database/PartitionScheme', @level_name=N'PartitionScheme', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only User DB', @target_set_level_id=0
GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Partition Scheme Name Pattern', @condition_name=N'Partition Scheme Name Pattern', @policy_category=N'Name_Pattern', @description=N'', @help_text=N'', @help_link=N'', @schedule_uid=N'00000000-0000-0000-0000-000000000000', @execution_mode=0, @is_enabled=False, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'Partition Scheme Name Pattern_ObjectSet'
Select @policy_id
GO





SELECT P.policy_id, P.name, PC.name FROM dbo.syspolicy_policies P
INNER JOIN dbo.syspolicy_policy_categories PC
	ON P.policy_category_id = PC.policy_category_id
WHERE PC.[name] = N'Name_Pattern'
