![](./media/solutions-microsoft-logo-small.png)

# OPTIMIZE_FOR_SEQUENTIAL_KEY

In SQL Server 2019, a new index option was added called [OPTIMIZE_FOR_SEQUENTIAL_KEY](https://docs.microsoft.com/sql/t-sql/statements/create-index-transact-sql#sequential-keys) that is intended to address an issue known as [last page insert contention](https://support.microsoft.com/kb/4460004). Most of the solutions to this problem that have been suggested in the past involve making changes to either the application or the structure of the contentious index, which can be costly and sometimes involve performance trade-offs. Rather than making major structural changes, OPTIMIZE_FOR_SEQUENTIAL_KEY addresses some of the SQL Server scheduling issues that can lead to severely reduced throughput when last page insert contention occurs. Using the OPTMIZE_FOR_SEQUENTIAL_KEY index option can help maintain consistent throughput in high-concurrency environments when the following conditions are true:

- The index has a sequential key
- The number of concurrent insert threads to the index far exceeds the number of schedulers (in other words logical cores)
- The index has a high rate of new page allocations (page splits), which is most often due to a large row size

This sample illustrates how OPTIMIZE_FOR_SEQUENTIAL_KEY can be used to improve throughput on workloads that are suffering from severe last page insert contention bottlenecks.

### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

- **Applies to:** SQL Server 2019 (or higher)
- **Workload:** High-concurrency OLTP
- **Programming Language:** T-SQL
- **Authors:** Pam Lahoud
- **Update history:** Created August 15, 2019

<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

1. SQL Server 2019 (or higher)
2. A server (physical or virtual) with multiple cores
3. The [AdventureWorks2016_EXT](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2016_EXT.bak) sample database

[!NOTE]
> This sample was designed for a server with 8 logical cores. If you run the sample on a server with more cores, you may need to increase the number of concurrent threads in order to observe the improvement.


<a name=run-this-sample></a>

## Run this sample

1. Copy the files from the root folder to a folder on the SQL Server.

2. Download [AdventureWorks2016_EXT.bak](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2016_EXT.bak) and restore it to your SQL Server 2019 instance.

3. From SQL Server Management Studio or Azure Data Studio, run the Setup.sql script.

4. Modify the SequentialInserts_Optimized.bat and SequentialInserts_Unoptimized.bat files and change the -S parameter to point to the server where the setup script was run. For example, `-S.\SQL2019` points to an instance named SQL2019 on the local server.

5. Open the SQL2019_LatchWaits.htm file to open a Performance Monitor session in your default browser.

6. Right-click anywhere in the browser window to clear the existing data from the session.

7. Click the play button to start the Performance Monitor session.

8. From a Command Prompt, browse to the folder that contains the demo files and run SequentialInserts_Unoptimized.bat, then return to the Performance Monitor window. You should see a high number of Page Latch waits as well as high average wait times. Note the time it takes for the script to complete.

9. Run the SequentialInserts_Optimized.bat script from the same Command Prompt window and again return to the Performance Monitor window. This time you should see much lower number and duration of Page Latch waits, along with higher Batch requests/sec. Note the time it takes for the script to complete, it should be significantly faster than the Unoptimized script.

10. **OPTIONAL** - Modify the `-n256` parameter in the Optimized and Unoptimized scripts to see the effect on performance. Generally, the larger the number of concurrent sessions, the greater the improvement will be with OPTIMIZE_FOR_SEQUENTIAL_KEY.



<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended to be a set of best practices on how to build scalable enterprise grade applications. This is beyond the scope of this quick start sample.

<a name=related-links></a>

## Related Links

For more information, see these articles:

[CREATE INDEX - Sequential Keys](https://docs.microsoft.com/sql/t-sql/statements/create-index-transact-sql#sequential-keys)

[Behind the Scenes on OPTIMIZE_FOR_SEQUENTIAL_KEY](https://techcommunity.microsoft.com/t5/SQL-Server/Behind-the-Scenes-on-OPTIMIZE-FOR-SEQUENTIAL-KEY/ba-p/806888)