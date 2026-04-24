Data Science for Database Professionals


As a data professional, do you wonder how you can leverage data science for creating new value in your organization? In this sample, learn how you can leverage your familiar knowledge on working with databases, and learn how you can get started with doing data science with databases.

----------

**Example**

Businesses need an effective strategy for managing customer churn. Customer churn includes customers stopping the use of a service, switching to a competitor service, switching to a lower-tier experience in the service or reducing engagement with the service.

In this use case, we look at how a mobile phone carrier company can proactively identify customers more likely to churn in the near term in order to improve the service and create custom outreach campaigns that help retain the customers.

Mobile phone carriers face an extremely competitive market. Many mobile carriers lose revenue from postpaid customers due to churn. Hence the ability to proactively and accurately identify customer churn at scale can be a huge competitive advantage. Some of the factors contributing to mobile phone customer churn includes: Perceived frequent service disruptions, poor customer service experiences in online/retail stores, offers from other competing carriers (better family plan, data plan, etc.).

Using a concrete example of building a predictive customer churn model for mobile service provider, we’ll share how you can jumpstart by
- Running R scripts using SQL Server as the compute context
- Operationalize your R scripts using stored procedures.


The insights delivered by these models are visualized using a Power BI dashboard
(e.g.[ https://powerbi.microsoft.com/en-us/industries/telco]( https://powerbi.microsoft.com/en-us/industries/telco)) or a SQL Report (telcoChurn-reportBuilder.rdl).

----------

**Pre-requirements**

You have to do the following set-up before playing with this demo.

- Install SQL Server 2016 or create a SQL Server 2016 Enterprise VM on Azure with Standalone R Server and R Services installed/configured.
- Install R IDE: R Tools for Visual Studio or R Studio.
- Install ReportBuilder for SQL Server 2016 Enterprise.
- Validate the successful installation.

----------

**Files**

This sample consists of the following directory structure.

- **Data** - Download the data files [edw_cdr.csv](https://sqlchoice.blob.core.windows.net/sqlchoice/samples/telco-customer-churn-v1/edw_cdr.csv) and [state_latlon.csv](https://sqlchoice.blob.core.windows.net/sqlchoice/samples/telco-customer-churn-v1/state_latlon.csv).
- **R** - This folder contains the R code that you can run in any R IDE.
- **SQL Server** - This folder contains the sql files that you can run to create T-SQL stored procedures (with R code embeded) and try out this telco churn example.
- **ReportBuilder** - This folder contains a sample SQL report created by ReportBuilder.

To jumpstart, run the T-SQL files (telcoChurn-operationalize.sql and telcoChurn-main.sql)






