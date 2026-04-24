-- Note this procedure is not included in the regular build, it
-- is called during the post deployment process.
-- This is due to the fact it updates temporal tables, and SSDT
-- will throw up an error when this occurs, despite the fact we
-- have procedures to deactivate the temporal tables and reactivate
-- when done.
DROP PROCEDURE IF EXISTS DataLoadSimulation.UpdateCustomFields;
GO

CREATE PROCEDURE DataLoadSimulation.UpdateCustomFields
@CurrentDateTime AS date
WITH EXECUTE AS OWNER
AS
BEGIN
    DECLARE @StartingWhen datetime2(7) = CAST(@CurrentDateTime AS date);

    SET @StartingWhen = DATEADD(hour, 23, @StartingWhen);

    -- Populate custom data for stock items

    UPDATE Warehouse.StockItems
    SET CustomFields = N'{ "CountryOfManufacture": '
                     + CASE WHEN IsChillerStock <> 0 THEN N'"USA", "ShelfLife": "7 days"'
                            WHEN StockItemName LIKE N'%USB food%' THEN N'"Japan"'
                            ELSE N'"China"'
                       END
                     + N', "Tags": []'
                     + CASE WHEN Size IN (N'S', N'XS', N'XXS', N'3XS') THEN N', "Range": "Children"'
                            WHEN Size IN (N'M') THEN N', "Range": "Teens/Young Adult"'
                            WHEN Size IN (N'L', N'XL', N'XXL', N'3XL', N'4XL', N'5XL', N'6XL', N'7XL') THEN N', "Range": "Adult"'
                            ELSE N''
                       END
                     + CASE WHEN StockItemName LIKE N'RC %' THEN N', "MinimumAge": "10"'
                            ELSE N''
                       END
                     + N' }',
        ValidFrom = @StartingWhen;

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Radio Control'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'RC %';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Realistic Sound'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'RC %';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Vintage'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%vintage%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Halloween Fun'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%halloween%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Super Value'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%pack of%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'So Realistic'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%ride on%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Comfortable'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%slipper%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Long Battery Life'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%slipper%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', CASE WHEN StockItemID % 2 = 0 THEN N'32GB' ELSE N'16GB' END),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%USB food%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'Comedy'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%joke%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Warehouse.StockItems
    SET CustomFields = JSON_MODIFY(CustomFields, N'append $.Tags', N'USB Powered'),
        ValidFrom = @StartingWhen
    WHERE StockItemName LIKE N'%USB%';

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE si
    SET si.CustomFields = JSON_MODIFY(si.CustomFields, N'append $.Tags', N'Limited Stock'),
        ValidFrom = @StartingWhen
    FROM Warehouse.StockItems AS si
    WHERE EXISTS (SELECT 1
                  FROM Warehouse.StockItemStockGroups AS sisg
                  INNER JOIN Warehouse.StockGroups AS sg
                  ON sisg.StockGroupID = sg.StockGroupID
                  WHERE si.StockItemID = sisg.StockItemID
                  AND sg.StockGroupName LIKE N'%Packaging%');

    -- populate custom data for employees and salespeople

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    DECLARE EmployeeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT PersonID, IsSalesperson
    FROM [Application].People
    WHERE IsEmployee <> 0;

    DECLARE @EmployeeID int;
    DECLARE @IsSalesperson bit;
    DECLARE @CustomFields nvarchar(max);
    DECLARE @JobTitle nvarchar(max);
    DECLARE @NumberOfAdditionalLanguages int;
    DECLARE @LanguageCounter int;
    DECLARE @OtherLanguages TABLE ( LanguageName nvarchar(50) );
    DECLARE @LanguageName nvarchar(50);

    OPEN EmployeeList;
    FETCH NEXT FROM EmployeeList INTO @EmployeeID, @IsSalesperson;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @CustomFields = N'{ "OtherLanguages": [] }';

        SET @NumberOfAdditionalLanguages = FLOOR(RAND() * 4);
        DELETE @OtherLanguages;
        SET @LanguageCounter = 0;
        WHILE @LanguageCounter < @NumberOfAdditionalLanguages
        BEGIN
            SET @LanguageName = (SELECT TOP(1) alias
                                 FROM sys.syslanguages
                                 WHERE alias NOT LIKE N'%English%'
                                 AND alias NOT LIKE N'%Brazil%'
                                 ORDER BY NEWID());
            IF @LanguageName LIKE N'%Chinese%' SET @LanguageName = N'Chinese';
            IF NOT EXISTS (SELECT 1 FROM @OtherLanguages WHERE LanguageName = @LanguageName)
            BEGIN
                INSERT @OtherLanguages (LanguageName) VALUES(@LanguageName);
                SET @CustomFields = JSON_MODIFY(@CustomFields, N'append $.OtherLanguages', @LanguageName);
            END;
            SET @LanguageCounter += 1;
        END;

        SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.HireDate',
                                        CONVERT(nvarchar(20), DATEADD(day, 0 - CEILING(RAND() * 2000) - 100, '20200101'), 126));

        SET @JobTitle = N'Team Member';
        SET @JobTitle = CASE WHEN RAND() < 0.05 THEN N'General Manager'
                             WHEN RAND() < 0.1 THEN N'Manager'
                             WHEN RAND() < 0.15 THEN N'Accounts Controller'
                             WHEN RAND() < 0.2 THEN N'Warehouse Supervisor'
                             ELSE @JobTitle
                        END;
        SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.Title', @JobTitle);

        IF @IsSalesperson <> 0
        BEGIN
            SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.PrimarySalesTerritory',
                                            (SELECT TOP(1) SalesTerritory FROM [Application].StateProvinces ORDER BY NEWID()));
            SET @CustomFields = JSON_MODIFY(@CustomFields, N'$.CommissionRate',
                                            CAST(CAST(RAND() * 5 AS decimal(18,2)) AS nvarchar(20)));
        END;

        UPDATE [Application].People
        SET CustomFields = @CustomFields,
            ValidFrom = @StartingWhen
        WHERE PersonID = @EmployeeID;

        FETCH NEXT FROM EmployeeList INTO @EmployeeID, @IsSalesperson;
    END;

    CLOSE EmployeeList;
    DEALLOCATE EmployeeList;

    -- Set user preferences

    SET @StartingWhen = DATEADD(minute, 1, @StartingWhen);

    UPDATE Application.People
    SET UserPreferences = N'{"theme":"'+ (CASE (PersonID % 7)
                                              WHEN 0 THEN 'ui-darkness'
                                              WHEN 1 THEN 'blitzer'
                                              WHEN 2 THEN 'humanity'
                                              WHEN 3 THEN 'dark-hive'
                                              WHEN 4 THEN 'ui-darkness'
                                              WHEN 5 THEN 'le-frog'
                                              WHEN 6 THEN 'black-tie'
                                              ELSE 'ui-lightness'
                                          END)
                        + N'","dateFormat":"' + CASE (PersonID % 10)
                                                    WHEN 0 THEN 'mm/dd/yy'
                                                    WHEN 1 THEN 'yy-mm-dd'
                                                    WHEN 2 THEN 'dd/mm/yy'
                                                    WHEN 3 THEN 'DD, MM d, yy'
                                                    WHEN 4 THEN 'dd/mm/yy'
                                                    WHEN 5 THEN 'dd/mm/yy'
                                                    WHEN 6 THEN 'mm/dd/yy'
                                                    ELSE 'mm/dd/yy'
                                                END
                        + N'","timeZone": "PST"'
                        + N',"table":{"pagingType":"' + CASE (PersonID % 5)
                                                            WHEN 0 THEN 'numbers'
                                                            WHEN 1 THEN 'full_numbers'
                                                            WHEN 2 THEN 'full'
                                                            WHEN 3 THEN 'simple_numbers'
                                                            ELSE 'simple'
                                                        END
                        + N'","pageLength": ' + CASE (PersonID % 5)
                                                    WHEN 0 THEN '10'
                                                    WHEN 1 THEN '25'
                                                    WHEN 2 THEN '50'
                                                    WHEN 3 THEN '10'
                                                    ELSE '10'
                                                END + N'},"favoritesOnDashboard":true}',
        ValidFrom = @StartingWhen
    WHERE UserPreferences IS NOT NULL;
END;
GO
