CREATE PROCEDURE [WebApi].[UpdateStateProvinceFromJson](@StateProvince NVARCHAR(MAX), @StateProvinceID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE	Application.StateProvinces SET
			StateProvinceCode = json.StateProvinceCode,
			StateProvinceName = json.StateProvinceName,
			CountryID = json.CountryID,
			SalesTerritory = json.SalesTerritory,
			LatestRecordedPopulation = json.LatestRecordedPopulation,
			LastEditedBy = @UserID
		FROM OPENJSON (@StateProvince)
			WITH (
				StateProvinceCode nvarchar(5) N'strict $.StateProvinceCode',
				StateProvinceName nvarchar(50) N'strict $.StateProvinceName',
				CountryID int N'strict $.CountryID',
				SalesTerritory nvarchar(50) N'strict $.SalesTerritory',
				LatestRecordedPopulation bigint) as json
		WHERE
			Application.StateProvinces.StateProvinceID = @StateProvinceID

END