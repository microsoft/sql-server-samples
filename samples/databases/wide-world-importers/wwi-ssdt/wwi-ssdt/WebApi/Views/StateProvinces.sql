CREATE VIEW [WebApi].[StateProvinces]
AS
SELECT sp.StateProvinceID, sp.StateProvinceCode, sp.StateProvinceName, sp.CountryID, sp.SalesTerritory, sp.LatestRecordedPopulation,
	Border = JSON_QUERY('{"type": "Feature","geometry":{' +
 (CASE sp.Border.STGeometryType()
	WHEN 'POLYGON' THEN
	'"type": "Polygon","coordinates":[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sp.Border.ToString(),'POLYGON ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
	WHEN 'MULTIPOLYGON' THEN
	'"type": "MultiPolygon","coordinates":[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sp.Border.ToString(),'MULTIPOLYGON ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
 ELSE NULL
 END)
+'}}'),
	c.CountryName
FROM	Application.StateProvinces AS sp
			INNER JOIN Application.Countries AS c
				ON c.CountryID = sp.CountryID
	 