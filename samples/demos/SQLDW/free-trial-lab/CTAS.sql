-- CTAS (Create Table as Select) Creates tables in the SQL DW from external tables

CREATE TABLE [dbo].[Date]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[Date]
OPTION (LABEL = 'CTAS : Load [dbo].[Date]')
;


CREATE TABLE [dbo].[Geography]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[Geography]
OPTION (LABEL = 'CTAS : Load [dbo].[Geography]')
;

CREATE TABLE [dbo].[HackneyLicense]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[HackneyLicense]
OPTION (LABEL = 'CTAS : Load [dbo].[HackneyLicense]')
;

CREATE TABLE [dbo].[Medallion]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[Medallion]
OPTION (LABEL = 'CTAS : Load [dbo].[Medallion]')
;

CREATE TABLE [dbo].[Time]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[Time]
OPTION (LABEL = 'CTAS : Load [dbo].[Time]')
;

CREATE TABLE [dbo].[Weather]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[Weather]
OPTION (LABEL = 'CTAS : Load [dbo].[Weather]')
;

CREATE TABLE [dbo].[Trip]
WITH
(   DISTRIBUTION = ROUND_ROBIN
,   CLUSTERED COLUMNSTORE INDEX
)
AS
SELECT *
FROM [ext].[Trip]
OPTION (LABEL = 'CTAS : Load [dbo].[Trip]')
;
