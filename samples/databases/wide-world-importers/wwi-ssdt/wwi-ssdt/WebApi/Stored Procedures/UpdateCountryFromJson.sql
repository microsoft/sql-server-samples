CREATE PROCEDURE [WebApi].[UpdateCountryFromJson](@Country NVARCHAR(MAX), @CountryID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN	UPDATE Application.Countries SET
				CountryName = json.CountryName,
				FormalName = json.FormalName,
				IsoAlpha3Code = json.IsoAlpha3Code,
				IsoNumericCode = json.IsoNumericCode,
				CountryType = json.CountryType,
				LatestRecordedPopulation = json.LatestRecordedPopulation,
				Continent = json.Continent,
				Region = json.Region,
				Subregion = json.Subregion,
				LastEditedBy = @UserID
			FROM OPENJSON (@Country)
				WITH (
					CountryName nvarchar(60) N'strict $.CountryName',
					FormalName nvarchar(60) N'strict $.FormalName',
					IsoAlpha3Code nvarchar(3),
					IsoNumericCode int,
					CountryType nvarchar(20),
					LatestRecordedPopulation bigint,
					Continent nvarchar(30) N'strict $.Continent',
					Region nvarchar(30) N'strict $.Region',
					Subregion nvarchar(30) N'strict $.Subregion') as json
			WHERE
				Application.Countries.CountryID = @CountryID
END