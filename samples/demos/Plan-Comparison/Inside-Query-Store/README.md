The plan comparison tool is used inside Query Store UI to allow plan comparison.

###Prerequisites
Restore QueryStoreTest database from provided .bacpac (/Databases/Import Data-tier application).

###Query with plan regression
1. Run QueryStoreSimpleDemo.exe with option R
2. Open SSMS, and under QueryStoreTest database, expand Query Store.
3. Open the *Top Resource Consuming Queries* report.
4. For query id 1 there are two execution plans that SQL Server use alternately (switches between 2 plan almost randomly).
5. Select one of the plans in the right pane, and while holding the Shift key, select the other plan.
6. On the top ribbon in the same pane, click on *Compare the plans for the selected query in a seperate window* - this brings up Plan Comparison.
7. In the *Properties* window you are able to spot some differences in the SELECT node. Expand the *Parameter List* and observe how the *Parameter Compiled Value* is different on both plans.
This is known as Parameter Sniffing problem - plan gets generated based on parameter available at the compilation time.
When compilation happens frequently and randomly and data is skewed (not all parameter values are uniformly distributed).

Knowing the cause, you can chose to force the perceived better plan for most use cases.
This can fix performance quickly and is fully transparent to running apps.
