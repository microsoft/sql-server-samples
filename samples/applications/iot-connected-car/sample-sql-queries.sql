--====================================================================
-- Step 1: Sample Analytical Queries - While the Data Ingestion is going on
--====================================================================
	-- Query the In-Memory OLTP Table for all the latest Safety Telemetry Events
	SELECT	EventID,
			EventMessage,
			City,
			OutsideTemperature,
			EngineTemperature,
			Speed,
			Fuel,
			EngineOil,
			TirePressure,
			Odometer,
			AcceleratorPedalPosition,
			ParkingBrakeStatus,
			HeadlampStatus,
			BrakePedalStatus,
			TransmissionGearPosition,
			IgnitionStatus,
			WindshieldWiperStatus,
			Abs
	FROM	Events
	WHERE	EventCategoryId = 2; -- Safety Event
	 	
	-- Query the Temporal Disk based Table for ALL Telemetry data for a specific car	
	SELECT	*
	FROM	EventsHistory
	WHERE	AutoID = 50;

	SELECT	EventMessage,
			AVG(Speed) AS AvgSpeed, 			
			AVG(EngineTemperature) AS AvgEngineTemperature,
			AVG(EngineOil) AS AvgEngineOil,
			AVG(TirePressure) AS AvgTirePressure,
			MIN(TransmissionGearPosition) AS MinGearPosition,
			MAX(TransmissionGearPosition) AS MinGearPosition,
			AVG(TransmissionGearPosition) AS AvgGearPosition
	FROM	EventsHistory
	WHERE	AutoID = 50
	GROUP BY EventMessage;

--=====================================================
-- Step 2: Sample SQL Graph Queries with Nodes and Edges
--=====================================================

-- Rohan's Cars
SELECT	p.fullname, a1.AutoID, a1.OwnerID, a1.VIN, a1.Make, a1.Model, a1.Year, a1.DriveTrain, a1.EngineType, a1.ExteriorColor, a1.InteriorColor, a1.Transmission
FROM	Person p, owns_auto o1, Auto a1
WHERE	MATCH(a1<-(o1)-p)
AND		p.PersonID = 81

-- Find all Rohan's friends who drive the same car as Rohan
SELECT	f.fullname, a.AutoID, a.VIN, a.Make, a.Model, a.Year, a.DriveTrain, a.EngineType, a.ExteriorColor, a.InteriorColor, a.Transmission
FROM	Person p, owns_auto o1, auto a1, is_friend_of isf, Person f, owns_auto o, auto a
WHERE	MATCH(a1<-(o1)-p-(isf)->f-(o)->a)
AND		p.PersonID = 81
AND		a1.model = a.model
AND		a1.model = 'Convertible 2DR'

-- Get driving score for Rohan and his friends
SELECT	p.fullname, dr.Rank, dr.Rating, dr.overall_score, dr.Trend, dr.rank_change
FROM	Person p, has_score h, DriveScore dr
WHERE	MATCH(p-(h)->dr)
AND		p.PersonID = 81
UNION
SELECT  f.fullname, ds.Rank, ds.Rating, ds.overall_score, ds.Trend, ds.rank_change
FROM	Person pp, is_friend_of isfof, Person f, has_score hs, DriveScore ds
WHERE	MATCH(pp-(isfof)->f-(hs)->ds)
and		pp.PersonID = 81

-- Compare Rohan's Driving Score with Shreya's Driving Score
SELECT  p.fullname, dr.Rank, dr.Rating, dr.overall_score, dr.Trend
FROM	Person p, has_score h, DriveScore dr
WHERE	MATCH(p-(h)->dr)
AND		p.PersonID = 81 -- Rohan
UNION
SELECT  p.fullname, dr.Rank, dr.Rating, dr.overall_score, dr.Trend
FROM	Person p, has_score h, DriveScore dr
WHERE	MATCH(p-(h)->dr)
AND		p.PersonID = 85 -- Shreya


