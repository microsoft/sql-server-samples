-- =========================================
-- Create Graph Edge Table Template
-- =========================================
USE <database, sysname, AdventureWorks>
GO

DROP TABLE IF EXISTS <schema_name, sysname, dbo>.<table_name, sysname, sample_edgetable>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_edgetable>
(
    -- Columns are optional for Graph Edge Tables.
    --
    <column1_name, sysname, c1> <column1_datatype, , int> <column1_nullability, , NOT NULL>,
    <column2_name, sysname, c2> <column2_datatype, , char(10)> <column2_nullability, , NULL>,
    <column3_name, sysname, c3> <column3_datatype, , datetime> <column3_nullability, , NULL>,

    -- System generated edge constraint.
    --
    CONNECTION (<node_table_name TO <node_table_name>),

    CONSTRAINT EC_<constraint_name> CONNECTION (<node_table_name TO <node_table_name>, <node_table_name> TO <node_table_name>),
    -- Unique index on $edge_id is required.
    -- If no user-defined index is specified, a default index is created.
    --
    INDEX ix_graphid UNIQUE ($edge_id),

    -- indexes on $from_id and $to_id are optional, but support faster lookups.
    --
    INDEX ix_fromid ($from_id, $to_id),
    INDEX ix_toid ($to_id, $from_id)
)
AS EDGE
GO
