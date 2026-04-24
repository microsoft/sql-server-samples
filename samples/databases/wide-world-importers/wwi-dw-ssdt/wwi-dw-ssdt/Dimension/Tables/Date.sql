CREATE TABLE [Dimension].[Date] (
    [Date]                                DATE          NOT NULL  -- 2013-01-01
  , [DateKey]                             INT           NOT NULL  -- 20130101
  , [Day Number]                          INT           NOT NULL  -- 1 (to last day of month)
  , [Day]                                 NVARCHAR (10) NOT NULL  -- 1 (to last day of month)
  , [Day of Year]                         NVARCHAR (5)  NOT NULL  -- 1 (to 365)
  , [Day of Year Number]                  INT           NOT NULL  -- 1 (to 365)
  , [Day of Week]                         NVARCHAR (20) NOT NULL  -- Tuesday
  , [Day of Week Number]                  INT           NOT NULL  -- 3
  , [Week of Year]                        NVARCHAR (5)  NOT NULL  -- 1
  , [Month]                               NVARCHAR (10) NOT NULL  -- January
  , [Short Month]                         NVARCHAR (3)  NOT NULL  -- Jan
  , [Quarter]                             NVARCHAR (2)  NOT NULL  -- Q1 (to Q4)
  , [Half of Year]                        NVARCHAR (3)  NOT NULL  -- H1 (or H2)
  , [Beginning of Month]                  DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Quarter]                DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Half Year]              DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Year]                   DATE          NOT NULL  -- 2013-01-01
  , [Beginning of Month Label]            NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Month Label Short]      NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Beginning of Quarter Label]          NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Quarter Label Short]    NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Beginning of Half Year Label]        NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Half Year Label Short]  NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Beginning of Year Label]             NVARCHAR (40) NOT NULL  -- January 1, 2013
  , [Beginning of Year Label Short]       NVARCHAR (40) NOT NULL  -- Jan 1, 2013
  , [Calendar Day Label]                  NVARCHAR (20) NOT NULL  -- January 1, 2013
  , [Calendar Day Label Short]            NVARCHAR (20) NOT NULL  -- Jan 1, 2013
  , [Calendar Week Number]                INT           NOT NULL  -- 1
  , [Calendar Week Label]                 NVARCHAR (20) NOT NULL  -- CY2013-W01
  , [Calendar Month Number]               INT           NOT NULL  -- 1 (to 12)
  , [Calendar Month Label]                NVARCHAR (20) NOT NULL  -- CY2013-Jan
  , [Calendar Month Year Label]           NVARCHAR (20) NOT NULL  -- Jan-2013
  , [Calendar Quarter Number]             INT           NOT NULL  -- 1 (to 4)
  , [Calendar Quarter Label]              NVARCHAR (20) NOT NULL  -- CY2013-Q1
  , [Calendar Quarter Year Label]         NVARCHAR (20) NOT NULL  -- Q1-2013
  , [Calendar Half of Year Number]        INT           NOT NULL  -- 1 (to 2)
  , [Calendar Half of Year Label]         NVARCHAR (20) NOT NULL  -- CY2013-H1
  , [Calendar Year Half of Year Label]    NVARCHAR (20) NOT NULL  -- H1-2013
  , [Calendar Year]                       INT           NOT NULL  -- 2013
  , [Calendar Year Label]                 NVARCHAR (10) NOT NULL  -- CY2013
  , [Fiscal Month Number]                 INT           NOT NULL  -- 3
  , [Fiscal Month Label]                  NVARCHAR (20) NOT NULL  -- FY2013-Jan
  , [Fiscal Quarter Number]               INT           NOT NULL  -- 2
  , [Fiscal Quarter Label]                NVARCHAR (20) NOT NULL  -- FY2013-Q2
  , [Fiscal Half of Year Number]          INT           NOT NULL  -- 1 (to 2)
  , [Fiscal Half of Year Label]           NVARCHAR (20) NOT NULL  -- FY2013-H2
  , [Fiscal Year]                         INT           NOT NULL  -- 2013
  , [Fiscal Year Label]                   NVARCHAR (10) NOT NULL  -- FY2013
  , [Date Key]                            INT           NOT NULL  -- 20130101 (to 20131231)
  , [Year Week Key]                       INT           NOT NULL  -- 201301 (to 201353)
  , [Year Month Key]                      INT           NOT NULL  -- 201301 (to 201312)
  , [Year Quarter Key]                    INT           NOT NULL  -- 20131  (to 20134)
  , [Year Half of Year Key]               INT           NOT NULL  -- 20131  (to 20132)
  , [Year Key]                            INT           NOT NULL  -- 2013
  , [Beginning of Month Key]              INT           NOT NULL  -- 20130101
  , [Beginning of Quarter Key]            INT           NOT NULL  -- 20130101
  , [Beginning of Half Year Key]          INT           NOT NULL  -- 20130101
  , [Beginning of Year Key]               INT           NOT NULL  -- 20130101
  , [Fiscal Year Month Key]               INT           NOT NULL  -- 201301 (to 201312)
  , [Fiscal Year Quarter Key]             INT           NOT NULL  -- 20131 (to 20134)
  , [Fiscal Year Half of Year Key]        INT           NOT NULL  -- 20131 (to 20132)
  , [ISO Week Number]                     INT           NOT NULL  -- 1
    CONSTRAINT [PK_Dimension_Date] PRIMARY KEY CLUSTERED ([Date] ASC)
);
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = N'Date dimension'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'DW key for date dimension (actual date is used for key)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Date';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The date in integer format, can be used as the DW Key if desired'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'DateKey';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day of the month in integer format (1 to the last day of the month, 28 30 or 31 typically)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day of the month in string format (1 to the last day of the month, 28 30 or 31 typically)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day number of year (1 to 365) as a string'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day number of year (1 to 365) as an integer'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Year Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Day of the week (Monday, Tuesday, etc)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Week';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Numeric day of the week (1=Sunday, etc)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Day of Week Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Week number of the year as a string'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Week of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The full month name (January)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Month';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The abbreviated current month (Jan)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Short Month';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The current quarter as text (Q1, Q2, etc)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Quarter';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Half of the year (H1, H2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Half of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first day of the month in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first day of the quarter in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first date of the current half of year in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The first day of the year in date format'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the month as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the month as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the quarter as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the quarter as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the current half of the year as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the current half year as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the year as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'First day of the year as a string with the month abbreviated (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Current day of the year as a string (January 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Day Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Current day of the year as a string with abbreviated month (Jan 1, 2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Day Label Short';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Week Number of the Year'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Week Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Week of the year as a displayable string (CY2013-W01)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Week Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Month of the year as a number'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Month Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Year and month as a string (CY2013-Jan)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Month Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Alternate format for year month with month first (Jan-2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Month Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Quarter number of the year (1 to 4)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Quarter Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Year and Quarter as string (CY2013-Q1)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Quarter Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Alternate form of Year/Quarter with Quarter first (Q1-2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Quarter Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Number denoting which half of the year (1 or 2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Half of Year Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Year and half the year (CY2013-H1)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Half of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Alternate form of half the year label (H1-2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Year Half of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Calendar Year as an integer'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Calendar Year as a formatted string (CY2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Calendar Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Month Number of the Fiscal year'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Month Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'Fiscal Year Month formatted as a string (FY2013-Jan)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Month Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Quarter Number of the Fiscal year (1 to 4)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Quarter Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Year and Quarter as a string (FY2013-Q3)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Quarter Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Half of Year as a number (1 or 2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Half of Year Number';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Half of Year as a formatted string (FY2013-H2)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Half of Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Year as a number (2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The Fiscal Year as a formatted string (FY2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Label';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current date (20130101 to 20131231)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Date Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-week (201301 to 201353)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Week Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-month (201301 to 201312)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Month Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-quarter (20131 to 20134)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Quarter Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year-half of year (20131 to 20132)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Half of Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current year (2013)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of the month (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Month Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of quarter (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Quarter Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of the half year (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Half Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current beginning of the year (20130101)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Beginning of Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current fiscal year month (201301 to 201312)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Month Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current fiscal year quarter (20131 to 20134)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Quarter Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'An integer that can be used as a key for the current fiscal year half of year (20131 to 20132)'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'Fiscal Year Half of Year Key';
GO

EXECUTE sp_addextendedproperty @name = N'Description'
      , @value = 'The ISO Week Number'
      , @level0type = N'SCHEMA'
      , @level0name = N'Dimension'
      , @level1type = N'TABLE'
      , @level1name = N'Date'
      , @level2type = N'COLUMN'
      , @level2name = N'ISO Week Number';
GO


