# Power BI Dashboards for WideWorldImporters

Sample Power BI dashboards for use with the WideWorldImporters and WideWorldImportersDW sample databases.


### Contents

[About this sample](#about-this-sample)<br/>
[Before you begin](#before-you-begin)<br/>
[Run this sample](#run-this-sample)<br/>
[Disclaimers](#disclaimers)<br/>
[Related links](#related-links)<br/>


<a name=about-this-sample></a>

## About this sample

<!-- Delete the ones that don't apply -->
1. **Applies to:** SQL Server 2016 (or higher), Azure SQL Database
1. **Key features:** Power BI
1. **Workload:** BI
1. **Programming Language:** Power BI Desktop
1. **Authors:** Jos de Bruijn
1. **Update history:**
	2 January 2018 - initial revision


<a name=before-you-begin></a>

## Before you begin

To run this sample, you need the following prerequisites.

**Software prerequisites:**

<!-- Examples -->
1. [WideWorldImporters](../wwi-ssdt/) and [WideWorldImportersDW](../wwi-dw-ssdt/) sample databases running in SQL Server 2016 (or higher) or Azure SQL Database. Install from source code.
1. Power BI Desktop. Download link: [https://powerbi.microsoft.com/downloads/](https://powerbi.microsoft.com/downloads/)

<a name=run-this-sample></a>

## Run this sample

1. Open the dashboard in Power BI Desktop.
2. Click the drop-down under **Edit Queries** and select **Data Source Settings**. A dialog box will open showing the data source configured in the dashboard.
3. Click **Change Source** and edit the **Server** to point to the SQL Server instance that hosts the WideWorldImporters and WideWorldImportersDW databases.
4. Click **OK** to save the changes, and click **Refresh** to update the data in the dashboard.

The following dashboards are available:

- [WWIDW-Sales.pbix](WWIDW-Sales.pbix) - Historical analysis of sales data from the WideWorldImportersDW OLAP database.
- [WWI-SalesOrders.pbix](WWI-SalesOrders.pbix) - Real-time analysis of sales in the WideWorldImporters operational database. Run [data generation](https://docs.microsoft.com/sql/sample/world-wide-importers/data-generation) in the WideWorldImporters database before using this dashboard for the best experience.


<a name=disclaimers></a>

## Disclaimers
The code included in this sample is not intended to be used for production purposes.

<a name=related-links></a>

## Related Links
<!-- Links to more articles. Remember to delete "en-us" from the link path. -->
For more information, see these articles:
- [SQL Server 2016 product page](https://www.microsoft.com/server-cloud/products/sql-server-2016/)
- [SQL Server 2016 download page](https://www.microsoft.com/evalcenter/evaluate-sql-server-2016)
- [Azure SQL Database product page](https://azure.microsoft.com/services/sql-database/)
- [What's new in SQL Server 2016](https://msdn.microsoft.com/en-us/library/bb500435.aspx)
