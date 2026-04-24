DROP FUNCTION IF EXISTS dbo.AsGeoJson
 GO
 CREATE FUNCTION dbo.AsGeoJson( @geo geography)
 RETURNS nvarchar(MAX) AS
 BEGIN
 RETURN (
 '{' +
 (CASE @geo.STGeometryType()
 WHEN 'POINT' THEN
 '"type": "Point","coordinates":' +
 REPLACE(REPLACE(REPLACE(REPLACE(@geo.ToString(),'POINT ',''),'(','['),')',']'),' ',',')
 WHEN 'POLYGON' THEN
 '"type": "Polygon","coordinates":' +
 '[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@geo.ToString(),'POLYGON ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
 WHEN 'MULTIPOLYGON' THEN
 '"type": "MultiPolygon","coordinates":' +
 '[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@geo.ToString(),'MULTIPOLYGON ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
 WHEN 'MULTIPOINT' THEN
 '"type": "MultiPoint","coordinates":' +
 '[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@geo.ToString(),'MULTIPOINT ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
 WHEN 'LINESTRING' THEN
 '"type": "LineString","coordinates":' +
 '[' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@geo.ToString(),'LINESTRING ',''),'(','['),')',']'),'], ',']],['),', ','],['),' ',',') + ']'
 ELSE NULL
 END)
 +'}')
 END