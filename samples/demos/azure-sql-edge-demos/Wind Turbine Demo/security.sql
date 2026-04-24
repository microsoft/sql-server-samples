/* Create users using the logins created */
CREATE USER OperatorUser WITHOUT LOGIN;
CREATE USER DataScientistUser WITHOUT LOGIN;
CREATE USER SecurityUser WITHOUT LOGIN;
CREATE USER TurbineUser WITHOUT LOGIN;

/* Grand permissions to users */
GRANT SELECT ON RealtimeSensorRecord TO OperatorUser;
GRANT SELECT ON RealtimeSensorRecord TO DataScientistUser;
GRANT SELECT ON RealtimeSensorRecord TO SecurityUser;
GRANT SELECT, INSERT ON RealtimeSensorRecord TO TurbineUser;


-- Mask the last four digits of the serial number (Sensor ID) of the sensor for the Data Scientist
ALTER TABLE RealtimeSensorRecord
ALTER COLUMN SensorId varchar(50) MASKED WITH (FUNCTION = 'partial(34,"XXXX",0)');
DENY UNMASK TO DataScientistUser;
GO

/**
* Operator: Can see all events
* Data Scientist: Can see everything BUT Hatch Sensor events
* Security: Can ONLY see HatchSensor events
*/
ALTER TABLE RealtimeSensorRecord
ALTER COLUMN SensorType sysname
GO

CREATE SCHEMA Security;
GO

/**
* Operator: Can see all events
* Data Scientist: Can see everything BUT Hatch Sensor events
* Security: Can ONLY see HatchSensor events
*/
CREATE FUNCTION Security.fn_securitypredicate(@SensorType AS sysname)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_securitypredicate_result
	WHERE
		USER_NAME() = 'OperatorUser' OR USER_NAME() = 'dbo' OR
		(USER_NAME() = 'DataScientistUser' AND @SensorType <> 'HatchSensor') OR
		(USER_NAME() = 'SecurityUser' AND @SensorType = 'HatchSensor');

CREATE SECURITY POLICY SensorsDataFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(SensorType)
ON dbo.RealtimeSensorRecord
WITH (STATE = ON);

/* QUERIES FOR TESTING POLICIES */

-- Testing basic policy to deny delete
EXECUTE AS USER = 'OperatorUser';
SELECT * FROM RealtimeSensorRecord;
DELETE FROM RealtimeSensorRecord WHERE SensorType = 'GeneratorTorque';
REVERT;

-- Testing the masking for data Data Scientist
EXECUTE AS USER = 'DataScientistUser';
SELECT TOP 10 * FROM RealtimeSensorRecord;
REVERT;

-- Testing Row-Level Security policy with Operator that can see all the events
EXECUTE AS USER = 'OperatorUser';
SELECT * FROM RealtimeSensorRecord;
REVERT;

-- Testing Row-Level Security policy with DataScientist that can see all the events but HatchSensor
EXECUTE AS USER = 'DataScientistUser';
SELECT * FROM RealtimeSensorRecord;
REVERT;

-- Testing Row-Level Security policy with Security that can see only the HatchSensor events
EXECUTE AS USER = 'SecurityUser';
SELECT * FROM RealtimeSensorRecord;
REVERT;
