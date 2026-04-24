CREATE VIEW [WebApi].[Cities]
AS
SELECT c.CityID, c.CityName, c.LatestRecordedPopulation, c.StateProvinceID, sp.StateProvinceName,
	Location = JSON_QUERY((SELECT
				type = 'Feature',
				[geometry.type] = 'Point',
				[geometry.coordinates] = JSON_QUERY(CONCAT('[',c.Location.Long,',',c.Location.Lat ,']'))
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER))
FROM Application.Cities c
	INNER JOIN Application.StateProvinces sp
		ON c.StateProvinceID = sp.StateProvinceID