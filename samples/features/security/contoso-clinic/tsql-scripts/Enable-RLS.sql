-- Reset the demo
DROP SECURITY POLICY IF EXISTS Security.patientSecurityPolicy
DROP FUNCTION IF EXISTS Security.patientAccessPredicate
DROP SCHEMA IF EXISTS Security
go

-- Observe existing schema
SELECT * FROM Patients
go

-- Mapping table, assigning application users to patients
-- We'll use RLS to ensure that application users can only access patients assigned to them
SELECT * FROM ApplicationUserPatients
go

-- Create separate schema for RLS objects
-- (not required, but best practice to limit access)
CREATE SCHEMA Security
go

-- Create predicate function for RLS
-- This determines which users can access which rows
CREATE FUNCTION Security.patientAccessPredicate(@PatientID int)
	RETURNS TABLE
	WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS isAccessible
	FROM dbo.ApplicationUserPatients
	WHERE
	(
		-- application users can access only patients assigned to them
		Patient_PatientID = @PatientID
		AND ApplicationUser_Id = CAST(SESSION_CONTEXT(N'UserId') AS nvarchar(128))
	)
	OR
	(
		-- DBAs can access all patients
		IS_MEMBER('db_owner') = 1
	)
go

-- Create security policy that adds this function as a security predicate on the Patients and Visits tables
--	Filter predicates filter out patients who shouldn't be accessible by the current user
--	Block predicates prevent the current user from inserting any patients who aren't mapped to them
CREATE SECURITY POLICY Security.patientSecurityPolicy
	ADD FILTER PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Patients,
	ADD BLOCK PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Patients,
	ADD FILTER PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Visits,
	ADD BLOCK PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Visits
go
