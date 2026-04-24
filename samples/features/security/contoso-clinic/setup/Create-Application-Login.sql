use Clinic;
go
-- Create a non-sysadmin account for the application to use

CREATE LOGIN [ContosoClinicApplication] WITH PASSWORD = <enter a strong password here>
CREATE USER [ContosoClinicApplication] FOR LOGIN [ContosoClinicApplication]
EXEC sp_addrolemember N'db_datareader', N'ContosoClinicApplication'
EXEC sp_addrolemember N'db_datawriter', N'ContosoClinicApplication'
GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO  [ContosoClinicApplication]
GRANT VIEW ANY COLUMN ENCRYPTION KEY  DEFINITION TO  [ContosoClinicApplication]


