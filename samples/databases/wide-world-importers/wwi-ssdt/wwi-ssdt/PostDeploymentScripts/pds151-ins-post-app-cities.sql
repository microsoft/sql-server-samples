/* Post insert A-Z Code*/
PRINT 'Executing Post Inserting Application.Cities Code'
GO

DELETE c
FROM [Application].Cities AS c
WHERE EXISTS (SELECT 1 FROM [Application].Cities AS cd
                       WHERE cd.CityName = c.CityName
					   AND cd.StateProvinceID = c.StateProvinceID
					   AND cd.CityID < c.CityID);

DELETE ca
FROM [Application].Cities_Archive AS ca
WHERE NOT EXISTS (SELECT 1 FROM [Application].Cities AS c
                           WHERE ca.CityID = c.CityID);
GO
