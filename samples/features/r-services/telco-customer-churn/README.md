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
(e.g.[ https://powerbi.microsoft.com/en-us/industries/telco]( https://powerbi.microsoft.com/en-us/industries/telco)).

----------

**Files**

This sample consists of the following directory structure.


- **R** - This folder contains the R code that you can run in any R IDE.
- **SQL Server** - This folder contains the SQL Server backup file (telcoedw2.bak) that you can restore to a SQL Server 2016 instance. The database telcoedw2.bak contains the data (train, test and new data) that you can use for exploring the example. The stored procedures (with R code) are included in the database.

To jumpstart, run the T-SQL file (TelcoChurn-Main.sql)






