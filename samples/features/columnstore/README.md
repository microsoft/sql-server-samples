# SQL Server columnstore

Columnstore indexes give great performance to queries that scan large sets of rows (millions of rows typically), and also provides huge savings in storage space. Typical compression rates can be 90%. They are best used for analytics queries, and are default for many data warehouse schemas.  When paired with nonclustered indexes, they can support OLTP queries efficiently as well.

The performance gains come from:

* Data is physically organized by column rather than using pages which hold a number of complete rows.
* Data in a single column compresses very well since it is typically in the same data domain.
* Queries only need to read the data for columns referenced in the query. No data from other columns needs to be read.
* Batch operations dramatically speed up aggregations on groups of rows at a time.

## Samples included

- **Nonclustered columnstore** - This demo walks through adding a nonclustered columnstore index to an OLTP table to enable fast analytics on an operational database.
- **In-Memory columnstore** - This demo walks through creating a columnstore index on a memory-optimized table to provide extremely fast analytics for In-Memory OLTP.
- **Ordered columnstore** - This sample determines the order quality for eligible columns of all columnstore indexes in a database.