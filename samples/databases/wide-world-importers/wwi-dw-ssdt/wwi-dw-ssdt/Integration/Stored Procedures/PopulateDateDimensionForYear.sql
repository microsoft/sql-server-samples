CREATE PROCEDURE Integration.PopulateDateDimensionForYear
@YearNumber int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DateCounter date = DATEFROMPARTS(@YearNumber, 1, 1);

    BEGIN TRY;

        BEGIN TRAN;

        WHILE YEAR(@DateCounter) = @YearNumber
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Dimension.[Date] WHERE [Date] = @DateCounter)
            BEGIN
                INSERT Dimension.[Date]
                       ( [Date]
                       , [DateKey]
                       , [Day Number]
                       , [Day]
                       , [Day of Year]
                       , [Day of Year Number]
                       , [Day of Week]
                       , [Day of Week Number]
                       , [Week of Year]
                       , [Month]
                       , [Short Month]
                       , [Quarter]
                       , [Half of Year]
                       , [Beginning of Month]
                       , [Beginning of Quarter]
                       , [Beginning of Half Year]
                       , [Beginning of Year]
                       , [Beginning of Month Label]
                       , [Beginning of Month Label Short]
                       , [Beginning of Quarter Label]
                       , [Beginning of Quarter Label Short]
                       , [Beginning of Half Year Label]
                       , [Beginning of Half Year Label Short]
                       , [Beginning of Year Label]
                       , [Beginning of Year Label Short]
                       , [Calendar Day Label]
                       , [Calendar Day Label Short]
                       , [Calendar Week Number]
                       , [Calendar Week Label]
                       , [Calendar Month Number]
                       , [Calendar Month Label]
                       , [Calendar Month Year Label]
                       , [Calendar Quarter Number]
                       , [Calendar Quarter Label]
                       , [Calendar Quarter Year Label]
                       , [Calendar Half of Year Number]
                       , [Calendar Half of Year Label]
                       , [Calendar Year Half of Year Label]
                       , [Calendar Year]
                       , [Calendar Year Label]
                       , [Fiscal Month Number]
                       , [Fiscal Month Label]
                       , [Fiscal Quarter Number]
                       , [Fiscal Quarter Label]
                       , [Fiscal Half of Year Number]
                       , [Fiscal Half of Year Label]
                       , [Fiscal Year]
                       , [Fiscal Year Label]
                       , [Date Key]
                       , [Year Week Key]
                       , [Year Month Key]
                       , [Year Quarter Key]
                       , [Year Half of Year Key]
                       , [Year Key]
                       , [Beginning of Month Key]
                       , [Beginning of Quarter Key]
                       , [Beginning of Half Year Key]
                       , [Beginning of Year Key]
                       , [Fiscal Year Month Key]
                       , [Fiscal Year Quarter Key]
                       , [Fiscal Year Half of Year Key]
                       , [ISO Week Number]
                       )
                SELECT [Date]
                       , [DateKey]
                       , [Day Number]
                       , [Day]
                       , [Day of Year]
                       , [Day of Year Number]
                       , [Day of Week]
                       , [Day of Week Number]
                       , [Week of Year]
                       , [Month]
                       , [Short Month]
                       , [Quarter]
                       , [Half of Year]
                       , [Beginning of Month]
                       , [Beginning of Quarter]
                       , [Beginning of Half of Year]
                       , [Beginning of Year]
                       , [Beginning of Month Label]
                       , [Beginning of Month Label Short]
                       , [Beginning of Quarter Label]
                       , [Beginning of Quarter Label Short]
                       , [Beginning of Half Year Label]
                       , [Beginning of Half Year Label Short]
                       , [Beginning of Year Label]
                       , [Beginning of Year Label Short]
                       , [Calendar Day Label]
                       , [Calendar Day Label Short]
                       , [Calendar Week Number]
                       , [Calendar Week Label]
                       , [Calendar Month Number]
                       , [Calendar Month Label]
                       , [Calendar Month Year Label]
                       , [Calendar Quarter Number]
                       , [Calendar Quarter Label]
                       , [Calendar Quarter Year Label]
                       , [Calendar Half of Year Number]
                       , [Calendar Half of Year Label]
                       , [Calendar Year Half of Year Label]
                       , [Calendar Year]
                       , [Calendar Year Label]
                       , [Fiscal Month Number]
                       , [Fiscal Month Label]
                       , [Fiscal Quarter Number]
                       , [Fiscal Quarter Label]
                       , [Fiscal Half of Year Number]
                       , [Fiscal Half of Year Label]
                       , [Fiscal Year]
                       , [Fiscal Year Label]
                       , [Date Key]
                       , [Year Week Key]
                       , [Year Month Key]
                       , [Year Quarter Key]
                       , [Year Half of Year Key]
                       , [Year Key]
                       , [Beginning of Month Key]
                       , [Beginning of Quarter Key]
                       , [Beginning of Half of Year Key]
                       , [Beginning of Year Key]
                       , [Fiscal Year Month Key]
                       , [Fiscal Year Quarter Key]
                       , [Fiscal Year Half of Year Key]
                       , [ISO Week Number]
                    FROM Integration.GenerateDateDimensionColumns(@DateCounter);
            END;
            SET @DateCounter = DATEADD(day, 1, @DateCounter);
        END;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to populate dates for the year';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
