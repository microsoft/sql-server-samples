-- ================================================
-- Product Assemblies Recursion Example template
-- ================================================
-- Uses a common table expression to selectively step through a recursive
-- relationship in a SELECT statement.
-- The following example shows the hierarchy of product assemblies and
-- components that are required to build the bicycle for ProductAssemblyID = 800.

USE <database_name,sysname,AdventureWorks>;
GO

WITH <CTE_name, sysname, Parts>(<assembly_id, sysname, AssemblyID>, <component_id, sysname, ComponentID>, PerAssemblyQty, EndDate, <level_col, sysname, ComponentLevel>) AS
(
    SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty,
        b.EndDate, 0 AS <level_col, sysname, ComponentLevel>
    FROM Production.BillOfMaterials AS b
    WHERE b.ProductAssemblyID = 800
          AND b.EndDate IS NULL
    UNION ALL
    SELECT bom.ProductAssemblyID, bom.ComponentID, p.PerAssemblyQty,
        bom.EndDate, <level_col, sysname, ComponentLevel> + 1
    FROM Production.BillOfMaterials AS bom
        INNER JOIN <CTE_name, sysname, Parts> AS p
        ON bom.ProductAssemblyID = p.<component_id, sysname, ComponentID>
        AND bom.EndDate IS NULL
)
SELECT <assembly_id, sysname, AssemblyID>, <component_id, sysname, ComponentID>, Name, PerAssemblyQty, EndDate,
        <level_col, sysname, ComponentLevel>
FROM <CTE_name, sysname, Parts> AS p
    INNER JOIN Production.Product AS pr
    ON p.<component_id, sysname, ComponentID> = pr.ProductID
ORDER BY <level_col, sysname, ComponentLevel>, <assembly_id, sysname, AssemblyID>, <component_id, sysname, ComponentID>;
GO
