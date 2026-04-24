USE AdventureWorks2014
GO

------------------------------------------------------------------------------------
-- Find all assemblies that require a Bearing Ball in the bill of materials
-- Or, Starting with a given node, find shortest paths to all the others nodes in
-- the graph
------------------------------------------------------------------------------------

SELECT
	P1.ProductID,
	P1.Name,
	STRING_AGG(P2.Name,'->') WITHIN GROUP (GRAPH PATH) AS [Assembly],
	LAST_VALUE(P2.ProductID) WITHIN GROUP (GRAPH PATH) AS [Final ProductID]
FROM
	PRODUCT P1,
	PRODUCT FOR PATH P2,
	ISPARTOF FOR PATH IPO
WHERE
	MATCH(SHORTEST_PATH(P1(-(IPO)->P2)+))
	AND P1.ProductID = 2
       ORDER BY P1.ProductID	

------------------------------------------------------------------------------------
-- Find all products which are up to 3 levels away from Bearing Ball in BOM hierarchy
-- Or, find shortest path from a given start node to all other nodes in the graph,
-- which are 1-3 hops away from the start node.
------------------------------------------------------------------------------------

SELECT
	P1.ProductID,
	P1.Name,
	STRING_AGG(P2.Name,'->') WITHIN GROUP (GRAPH PATH) AS [Assembly],
	LAST_VALUE(P2.ProductID) WITHIN GROUP (GRAPH PATH) AS [Final ProductID],
	COUNT(P2.ProductID) WITHIN GROUP (GRAPH PATH) AS Levels
FROM
	PRODUCT P1,
	PRODUCT FOR PATH P2,
	ISPARTOF FOR PATH IPO
WHERE
	MATCH(SHORTEST_PATH(P1(-(IPO)->P2){1,3}))
	AND P1.ProductID = 2
       ORDER BY P1.ProductID	


------------------------------------------------------------------------------------
-- Find shortest path between 2 given nodes (start node and end node)
-- Note that, to apply filter on the end node, we have to use a subquery
-- but the filter applied on end node in outer query is pushed down while
-- computing the shortest path.
------------------------------------------------------------------------------------

SELECT
	ProductID, Name, [Assembly], FinalProductID, Levels
FROM (
	SELECT
		P1.ProductID,
		P1.Name,
		STRING_AGG(P2.Name,'->') WITHIN GROUP (GRAPH PATH) AS [Assembly],
		LAST_VALUE(P2.ProductID) WITHIN GROUP (GRAPH PATH) AS FinalProductID,
		COUNT(P2.ProductID) WITHIN GROUP (GRAPH PATH) AS Levels
	FROM
		PRODUCT P1,
		PRODUCT FOR PATH P2,
		ISPARTOF FOR PATH IPO
	WHERE
		MATCH(SHORTEST_PATH(P1(-(IPO)->P2)+))
		AND P1.ProductID = 2
 ) AS Q
 WHERE Q.FinalProductID = 768


