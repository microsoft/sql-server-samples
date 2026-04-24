-- =================================================
-- Create SQL Login Must Change Password template
-- =================================================

CREATE LOGIN <SQL_login_name, sysname, login_name>
	WITH PASSWORD = N'<password, sysname, Change_Password>'
	MUST_CHANGE,
	CHECK_POLICY = <check_policy,ON or OFF, ON>;
GO
