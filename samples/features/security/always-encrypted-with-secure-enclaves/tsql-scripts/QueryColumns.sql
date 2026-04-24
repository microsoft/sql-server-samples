USE Clinic
GO

DECLARE @SSNSuffix [CHAR](11) = '%38'
DECLARE @LastNamePettern [NVARCHAR](50) = 'A%'
DECLARE @MinBirthDate [DATETIME2](7) = '19900101'
DECLARE @MaxBirthDate [DATETIME2](7) = '20150101'
SELECT * FROM [dbo].[Patients]
WHERE [SSN] LIKE @SSNSuffix
AND [LastName] LIKE @LastNamePettern
AND [BirthDate] >= @MinBirthDate AND [BirthDate] < @MaxBirthDate
GO