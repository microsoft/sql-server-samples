/*
This script determines the order quality for eligible columns of all columnstore indexes in the current database.
It can be used for columnstore indexes built with or without the ORDER clause to find explicitly declared or implict order.

For more information about order in columnstore indexes, see
https://learn.microsoft.com/sql/relational-databases/indexes/ordered-columnstore-indexes

The script works in SQL Server 2022 and later versions, Azure SQL Database, and Azure SQL Managed Instance.

The order quality for a column is defined as the average of the order quality of its segments.
The order quality for a segment is defined by the following formula:

order_quality_percent = (1 - segment_overlap_count / (total_segment_count - 1)) * 100

When a segment doesn't overlap with *any other* segment in a partition, its order quality is 100 percent.
When a segment overlaps with *every other* segment in a partition, its order quality is 0 percent.

The segment metadata required to determine order quality is exposed only for some data types and some encodings.
The script excludes the columns where metadata isn't available.
Even though order quality cannot be determined for ineligible columns using this script,
segment elimination for these columns can still be improved with higher order quality.
*/

DROP TABLE IF EXISTS #column_segment;

CREATE TABLE #column_segment
(
partition_id bigint NOT NULL,
object_id int NOT NULL,
index_id int NOT NULL,
partition_number int NOT NULL,
column_id int NOT NULL,
type_name sysname NOT NULL,
segment_id int NOT NULL,
row_count bigint NOT NULL,
on_disk_size bigint NOT NULL,
min_data_value varbinary(18) NOT NULL,
max_data_value varbinary(18) NOT NULL,
count_starts bigint NOT NULL,
count_ends bigint NOT NULL,
max_overlaps bigint NOT NULL,
PRIMARY KEY (partition_id, column_id, segment_id) WITH (DATA_COMPRESSION = ROW),
INDEX ix_starts (partition_id, column_id, min_data_value, count_starts) WITH (DATA_COMPRESSION = ROW),
INDEX ix_ends (partition_id, column_id, max_data_value, count_ends) WITH (DATA_COMPRESSION = ROW)
);

/*
Persist an indexed subset of sys.column_store_segments for eligible segments, i.e.
the segments using the types and encodings where trustworthy min/max data values are available in sys.column_store_segments.
*/
INSERT INTO #column_segment
(
partition_id,
object_id,
index_id,
partition_number,
column_id,
type_name,
segment_id,
row_count,
on_disk_size,
min_data_value,
max_data_value,
count_starts,
count_ends,
max_overlaps
)
SELECT cs.partition_id,
       p.object_id,
       p.index_id,
       p.partition_number,
       cs.column_id,
       t.name AS type_name,
       cs.segment_id,
       CAST(cs.row_count AS bigint) AS row_count,
       cs.on_disk_size,
       mm.min_data_value,
       mm.max_data_value,
       COUNT(1) OVER (
                     PARTITION BY cs.partition_id, cs.column_id
                     ORDER BY mm.min_data_value
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                     )
       AS count_starts, /* The cumulative number of segment starts before the start of the current segment */
       COUNT(1) OVER (
                     PARTITION BY cs.partition_id, cs.column_id
                     ORDER BY mm.max_data_value
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                     )
       AS count_ends, /* The cumulative number of segment ends before the end of the current segment */
       COUNT(1) OVER (
                     PARTITION BY cs.partition_id, cs.column_id
                     ) - 1
       AS max_overlaps /* The maximum number of overlaps is the number of segments minus one */
FROM sys.column_store_segments AS cs
INNER JOIN sys.partitions AS p
ON cs.partition_id = p.partition_id
INNER JOIN sys.columns AS c
ON p.object_id = c.object_id
   AND
   cs.column_id = c.column_id
INNER JOIN sys.types AS t
on c.user_type_id = t.user_type_id
CROSS APPLY (
            SELECT CASE
                   WHEN t.name IN ('bit','tinyint','smallint','bigint','money')
                        AND
                        cs.encoding_type IN (1,2) AND cs.min_data_id <= cs.max_data_id
                   THEN 'simple' /*
                                 min_data_id and max_data_id columns have the actual min/max data values for the segment.
                                 */
                   WHEN t.name IN ('binary','varbinary','char','nchar','varchar','nvarchar')
                        AND
                        cs.encoding_type IN (3,5) AND cs.min_deep_data <= cs.max_deep_data
                   THEN 'deep' /*
                               min_deep_data and max_deep_data columns are populated using a binary representation 
                               of the min/max data values for the segment, and the values are comparable.
                               */
                   ELSE 'unsupported'
                   END AS segment_type
            ) AS st
CROSS APPLY (
            SELECT CASE
                   WHEN st.segment_type = 'simple' THEN CAST(cs.min_data_id AS varbinary(18))
                   WHEN st.segment_type = 'deep' THEN cs.min_deep_data
                   END
                   AS min_data_value,
                   CASE
                   WHEN st.segment_type = 'simple' THEN CAST(cs.max_data_id AS varbinary(18))
                   WHEN st.segment_type = 'deep' THEN cs.max_deep_data
                   END
                   AS max_data_value
            ) AS mm
WHERE cs.partition_id IS NOT NULL AND cs.column_id IS NOT NULL AND cs.segment_id IS NOT NULL AND cs.row_count IS NOT NULL
      AND
      st.segment_type IN ('simple','deep');

/*
Return the result set.
Each row represents a column in a columnstore index.
*/
SELECT OBJECT_SCHEMA_NAME(cs.object_id) AS schema_name,
       OBJECT_NAME(cs.object_id) AS object_name,
       i.name AS index_name,
       COL_NAME(cs.object_id, cs.column_id) AS column_name,
       cs.type_name,
       cs.column_id,
       cs.partition_number,
       ic.column_store_order_ordinal,
       INDEXPROPERTY(cs.object_id, i.name, 'IsClustered') AS is_clustered_column_store,
       SUM(cs.row_count) AS row_count,
       CAST(SUM(cs.on_disk_size) / 1024. / 1024 AS decimal(28,3)) AS on_disk_size_mb,
       COUNT(1) AS eligible_segment_count,
       MIN(o.count_overlaps) AS min_segment_overlaps,
       AVG(o.count_overlaps) AS avg_segment_overlaps,
       MAX(o.count_overlaps) AS max_segment_overlaps,
       (1 - AVG(olr.overlap_ratio)) * 100 AS order_quality_percent
FROM #column_segment AS cs
INNER JOIN sys.indexes AS i
ON cs.object_id = i.object_id
   AND
   cs.index_id = i.index_id
INNER JOIN sys.index_columns AS ic
ON cs.object_id = ic.object_id
   AND
   cs.column_id = ic.column_id
OUTER APPLY (
            SELECT TOP (1) count_starts
            FROM #column_segment AS s
            WHERE s.partition_id = cs.partition_id
                  AND
                  s.column_id = cs.column_id
                  AND
                  s.min_data_value < cs.max_data_value
            ORDER BY s.min_data_value DESC
            ) AS s /* The max cumulative number of segment starts before the end of the current segment */
OUTER APPLY (
            SELECT TOP (1) count_ends
            FROM #column_segment AS e
            WHERE e.partition_id = cs.partition_id
                  AND
                  e.column_id = cs.column_id
                  AND
                  e.max_data_value <= cs.min_data_value
            ORDER BY e.max_data_value DESC
            ) AS e /* The max cumulative number of segment ends after the start of the current segment */
CROSS APPLY (
            /*
            For non-overlapping segments, the number of starts is the same as the number of ends.
            For overlapping segments, the difference is the number of overlaps.
            Subtract one to omit the current segment.
            */
            SELECT ISNULL(s.count_starts, 0) - ISNULL(e.count_ends, 0) - 1 AS diff
            ) AS d
CROSS APPLY (
            /*
            A negative difference occurs when the end of the previous segment is the same as
            the start of the next segment. In the context of columnstore, this is not an overlap.
            */
            SELECT IIF(d.diff >= 0, d.diff, 0) AS count_overlaps
            ) AS o
CROSS APPLY (
            SELECT CAST(o.count_overlaps AS float) / NULLIF(cs.max_overlaps, 0) AS overlap_ratio
            ) AS olr
GROUP BY cs.object_id, i.name, cs.type_name, cs.column_id, cs.partition_number, ic.column_store_order_ordinal
ORDER BY schema_name, object_name, index_name, column_id, column_store_order_ordinal;
