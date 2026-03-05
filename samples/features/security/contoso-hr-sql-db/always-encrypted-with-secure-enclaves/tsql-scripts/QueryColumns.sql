SELECT * FROM [dbo].[Employees];

DECLARE @SSN CHAR(11) = '795-73-9838'
SELECT * FROM [dbo].[Employees] WHERE [SSN] = @SSN;
GO

DECLARE @SSNPattern CHAR(11) = '%9838'
SELECT * FROM [dbo].[Employees] WHERE [SSN] LIKE @SSNPattern;
GO 

DECLARE @MinSalary MONEY = 40000
DECLARE @MaxSalary MONEY = 45000
SELECT * FROM [dbo].[Employees] WHERE [Salary] > @MinSalary AND [Salary] < @MaxSalary;
GO

DECLARE @LastNamePrefix NVARCHAR(50) = 'Aber%';
SELECT * FROM [dbo].[Employees] WHERE [LastName] LIKE @LastNamePrefix;
GO 