/* ============================================================================
DATE/TIME DISCOVERY - SQL2022 independent, read-only batch

Select everything from this comment through the final GO to inspect an existing
database. It uses catalog views only; it does not depend on DateTimeLab objects.
NULL scans all visible user schemas and database-scoped DDL triggers.
Set @DiscoverySchema = N'DateTimeLab' to restrict the report to the fixture.

Result sets:
  1. Scope, permissions, scanned-source counts, and inspection limitations.
  2. Summary by object type and artifact type, including sources with no matches.
  3. One row per matched artifact: parent/column/index and category totals.
  4. Every token occurrence: category, line/column, and source-line text.
  5. Actual date/time columns, UDF return types, and procedure/UDF parameters,
     including alias types. These are catalog-confirmed, not text guesses.
  6. Objects/expressions whose definitions could not be scanned.

The scanner examines SQL TEXT, not a parsed syntax tree. It deliberately retains
comments and quoted text, so dynamic-SQL literals remain visible. Such text,
quoted identifiers, and same-named user functions can be false positives.
CAST/CONVERT/PARSE/FORMAT are candidates: their arguments may not be date/time.
Date/type keywords are also candidates; result set 5 gives confirmed bindings.
ISO/compact date and time literals are candidates too (an eight-digit string
could instead be an identifier). Other literal formats are not recognized.
Matches are signatures/tokens, not balanced, complete nested function calls.
Calls built by concatenating strings, indirect UDF dependencies, synonyms,
cross-database objects, SQL Agent job steps, and server-level triggers are outside
this database-local scan. A no-match result is not proof of no date/time behavior.
Comments inserted between a function name and '(' or between operator keywords
are not treated as whitespace and can prevent a match. Delimiters are common
T-SQL punctuation and ASCII whitespace; unusual Unicode punctuation/whitespace
can prevent a match. Newer keywords inside comments/strings may still be reported.
Quoted-literal candidates are bounded by apostrophes; this is not SQL string
unescaping and does not reconstruct literals containing escaped apostrophes.

Line 1 is the first line of sys.sql_modules.definition, not the original script
file. Expression line numbers are relative to the catalog expression. CRLF and
lone CR are normalized to LF; character offsets refer to that normalized text.
SC collation keeps Unicode supplementary-character offsets consistent.
Line text is capped at 4,000 characters with an explicit truncation indicator.
Definitions exceeding @DiscoveryMaxBytes (2 MB by default, a work-budget limit
for this scanner, not a SQL2022 engine limit) are reported as gaps, not partially
scanned. Increase it deliberately for larger definitions. VIEW DEFINITION is recommended;
catalog rows invisible to the caller cannot be listed, even in the gaps report.

https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/patindex-transact-sql
============================================================================ */

SET NOCOUNT ON;
DECLARE @DiscoverySchema sysname = NULL;
DECLARE @DiscoveryMaxBytes int = 2097152;
DECLARE @HasViewDefinition bit =
    CASE WHEN HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') = 1
         THEN 1 ELSE 0 END;
DECLARE @EngineEdition int =
    COALESCE(CONVERT(int, SERVERPROPERTY('EngineEdition')), 0);
DECLARE @MajorVersion int =
    COALESCE(TRY_CONVERT(int, SERVERPROPERTY('ProductMajorVersion')), 0);

IF NOT
(
    -- Azure SQL Database, SQL Managed Instance, or Fabric SQL database.
    @EngineEdition IN (5, 8, 12)
    -- SQL Server 2022 (16.x) or later.
    OR (@EngineEdition IN (2, 3, 4) AND @MajorVersion >= 16)
)
    THROW 51051, 'This discovery batch requires SQL Server 2022 (16.x) or later, Azure SQL Database, Azure SQL Managed Instance, or Fabric SQL database.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()) < 160
    THROW 51052, 'This discovery batch requires compatibility level 160 or later.', 1;
IF @DiscoveryMaxBytes IS NULL OR @DiscoveryMaxBytes <= 0
    THROW 51053, 'DiscoveryMaxBytes must be a positive integer.', 1;
IF @DiscoverySchema IS NOT NULL AND SCHEMA_ID(@DiscoverySchema) IS NULL
    THROW 51050, 'The requested discovery schema does not exist or is not visible.', 1;
IF @HasViewDefinition = 0
    RAISERROR('Date/time discovery has limited metadata visibility. Objects may be absent; obtain VIEW DEFINITION for a complete visible-object inventory.', 10, 1);

DECLARE @Sources TABLE
(
    SourceId int IDENTITY(1,1) PRIMARY KEY,
    ObjectId int NOT NULL,
    ObjectType nvarchar(60) NOT NULL,
    SchemaName sysname NULL,
    ObjectName sysname NOT NULL,
    ParentObject nvarchar(517) NULL,
    ArtifactType nvarchar(40) NOT NULL,
    ArtifactName sysname NOT NULL,
    ColumnName sysname NULL,
    IsModule bit NOT NULL,
    IsDisabled bit NULL,
    IsNotTrusted bit NULL,
    IsEncrypted bit NULL,
    DefinitionBytes bigint NULL,
    ScanStatus varchar(40) NULL,
    ScanText nvarchar(max) COLLATE Latin1_General_100_CI_AS_SC NULL,
    FlatText nvarchar(max) COLLATE Latin1_General_100_CI_AS_SC NULL
);

-- User table types have internal, is_ms_shipped backing objects. Resolve their
-- public names/schemas explicitly rather than losing their columns/constraints.
DECLARE @ObjectCatalog TABLE
(
    ObjectId int PRIMARY KEY,
    ObjectType nvarchar(60) NOT NULL,
    SchemaName sysname NOT NULL,
    ObjectName sysname NOT NULL
);
INSERT @ObjectCatalog
SELECT o.object_id, o.type_desc, s.name, o.name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0 AND o.type <> 'TT'
  AND (@DiscoverySchema IS NULL OR s.name = @DiscoverySchema)
UNION ALL
SELECT tt.type_table_object_id, N'USER_TABLE_TYPE', s.name, tt.name
FROM sys.table_types AS tt
JOIN sys.schemas AS s ON s.schema_id = tt.schema_id
WHERE tt.is_user_defined = 1 AND (@DiscoverySchema IS NULL OR s.name = @DiscoverySchema);

-- Includes native T-SQL modules, CLR objects (reported as gaps), legacy rules
-- and standalone defaults. Ordinary constraints are collected separately.
INSERT @Sources
    (ObjectId, ObjectType, SchemaName, ObjectName, ParentObject,
     ArtifactType, ArtifactName, IsModule, IsDisabled, IsEncrypted, DefinitionBytes, ScanText)
SELECT o.object_id, o.type_desc, s.name, o.name,
       CASE WHEN o.parent_object_id <> 0 THEN
           QUOTENAME(OBJECT_SCHEMA_NAME(o.parent_object_id)) + N'.' +
           QUOTENAME(OBJECT_NAME(o.parent_object_id)) END,
       N'MODULE', o.name, 1, tr.is_disabled,
       CONVERT(bit, OBJECTPROPERTYEX(o.object_id, N'IsEncrypted')),
       DATALENGTH(m.definition), m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
LEFT JOIN sys.triggers AS tr ON tr.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('P', 'PC', 'V', 'FN', 'IF', 'TF', 'FS', 'FT', 'TR', 'TA', 'AF', 'RF', 'R', 'D')
  AND (@DiscoverySchema IS NULL OR s.name = @DiscoverySchema)
  AND NOT EXISTS (SELECT 1 FROM sys.default_constraints AS dc WHERE dc.object_id = o.object_id);

-- Database-scoped DDL triggers are in sys.triggers, not sys.objects.
INSERT @Sources
    (ObjectId, ObjectType, ObjectName, ArtifactType, ArtifactName,
     IsModule, IsDisabled, IsEncrypted, DefinitionBytes, ScanText)
SELECT tr.object_id,
       CASE WHEN tr.type = 'TA' THEN N'CLR_DATABASE_DDL_TRIGGER' ELSE N'SQL_DATABASE_DDL_TRIGGER' END,
       tr.name, N'MODULE', tr.name, 1, tr.is_disabled,
       CONVERT(bit, OBJECTPROPERTYEX(tr.object_id, N'IsEncrypted')),
       DATALENGTH(m.definition), m.definition
FROM sys.triggers AS tr
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id
WHERE tr.parent_class = 0 AND tr.is_ms_shipped = 0 AND @DiscoverySchema IS NULL;

INSERT @Sources
    (ObjectId, ObjectType, SchemaName, ObjectName, ParentObject,
     ArtifactType, ArtifactName, ColumnName, IsModule, DefinitionBytes, ScanText)
SELECT d.object_id, N'DEFAULT_CONSTRAINT', p.SchemaName, d.name,
       QUOTENAME(p.SchemaName) + N'.' + QUOTENAME(p.ObjectName),
       N'DEFAULT_CONSTRAINT', d.name, c.name, 0, DATALENGTH(d.definition), d.definition
FROM sys.default_constraints AS d
JOIN @ObjectCatalog AS p ON p.ObjectId = d.parent_object_id
JOIN sys.columns AS c ON c.object_id = p.ObjectId AND c.column_id = d.parent_column_id;

INSERT @Sources
    (ObjectId, ObjectType, SchemaName, ObjectName, ParentObject,
     ArtifactType, ArtifactName, ColumnName, IsModule, IsDisabled, IsNotTrusted,
     DefinitionBytes, ScanText)
SELECT c.object_id, N'CHECK_CONSTRAINT', p.SchemaName, c.name,
       QUOTENAME(p.SchemaName) + N'.' + QUOTENAME(p.ObjectName),
       N'CHECK_CONSTRAINT', c.name, COL_NAME(c.parent_object_id, c.parent_column_id),
       0, c.is_disabled, c.is_not_trusted, DATALENGTH(c.definition), c.definition
FROM sys.check_constraints AS c
JOIN @ObjectCatalog AS p ON p.ObjectId = c.parent_object_id;

INSERT @Sources
    (ObjectId, ObjectType, SchemaName, ObjectName,
     ArtifactType, ArtifactName, ColumnName, IsModule, DefinitionBytes, ScanText)
SELECT p.ObjectId, p.ObjectType, p.SchemaName, p.ObjectName,
       N'COMPUTED_COLUMN', c.name, c.name, 0, DATALENGTH(c.definition), c.definition
FROM sys.computed_columns AS c
JOIN @ObjectCatalog AS p ON p.ObjectId = c.object_id;

INSERT @Sources
    (ObjectId, ObjectType, SchemaName, ObjectName,
     ArtifactType, ArtifactName, IsModule, IsDisabled, DefinitionBytes, ScanText)
SELECT p.ObjectId, p.ObjectType, p.SchemaName, p.ObjectName,
       N'FILTERED_INDEX', i.name, 0, i.is_disabled,
       DATALENGTH(i.filter_definition), i.filter_definition
FROM sys.indexes AS i
JOIN @ObjectCatalog AS p ON p.ObjectId = i.object_id
WHERE i.has_filter = 1;

UPDATE @Sources
SET ScanStatus =
    CASE WHEN ScanText IS NULL AND
              (ObjectType LIKE N'CLR%' OR ObjectType LIKE N'%ASSEMBLY%' OR ObjectType = N'AGGREGATE_FUNCTION')
             THEN 'NO_TSQL_DEFINITION'
         WHEN ScanText IS NULL AND IsEncrypted = 1 THEN 'ENCRYPTED'
         WHEN ScanText IS NULL THEN 'DEFINITION_NOT_VISIBLE'
         WHEN DefinitionBytes > @DiscoveryMaxBytes THEN 'EXCEEDS_SCAN_SIZE_LIMIT'
         ELSE 'SCANNED' END,
    ScanText = CASE WHEN DefinitionBytes <= @DiscoveryMaxBytes
                   THEN REPLACE(REPLACE(ScanText, NCHAR(13) + NCHAR(10), NCHAR(10)), NCHAR(13), NCHAR(10))
                   END;

DECLARE @Whitespace nvarchar(5) = NCHAR(9) + NCHAR(10) + NCHAR(11) + NCHAR(12) + NCHAR(13);
DECLARE @Delimiters nvarchar(100) = @Whitespace + N'(){}[],.;:+-*/%=<>!~&|^?''"\';
UPDATE @Sources SET FlatText = TRANSLATE(ScanText, @Whitespace, N'     ');

DECLARE @Lines TABLE
(
    SourceId int NOT NULL,
    LineNumber int NOT NULL,
    StartPosition int NOT NULL,
    LineLength int NOT NULL,
    SourceLine nvarchar(4000) NULL,
    PRIMARY KEY (SourceId, StartPosition)
);
;WITH SplitLines AS
(
    SELECT d.SourceId, l.ordinal, l.value,
           CONVERT(int, LEN(l.value + N'#') - 1) AS LineLength
    FROM @Sources AS d
    CROSS APPLY STRING_SPLIT(d.ScanText, NCHAR(10), 1) AS l
),
Positioned AS
(
    SELECT *, 1 + COALESCE(SUM(CONVERT(bigint, LineLength) + 1) OVER
        (PARTITION BY SourceId ORDER BY ordinal ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS StartPosition
    FROM SplitLines
)
INSERT @Lines
SELECT SourceId, CONVERT(int, ordinal), CONVERT(int, StartPosition),
       LineLength, LEFT(value, 4000)
FROM Positioned;

DECLARE @Words TABLE
(
    SourceId int NOT NULL,
    StartPosition int NOT NULL,
    EndPosition int NOT NULL,
    Word nvarchar(128) COLLATE Latin1_General_100_CI_AS_SC NOT NULL,
    PRIMARY KEY (SourceId, StartPosition)
);
-- Keep empty tokens until their lengths have contributed to source offsets.
;WITH SplitWords AS
(
    SELECT d.SourceId, w.ordinal, w.value,
           LEN(w.value + N'#') - 1 AS WordLength
    FROM @Sources AS d
    CROSS APPLY STRING_SPLIT(
        TRANSLATE(d.ScanText, @Delimiters, REPLICATE(N' ', LEN(@Delimiters))), N' ', 1) AS w
),
Positioned AS
(
    SELECT *, 1 + COALESCE(SUM(WordLength + 1) OVER
        (PARTITION BY SourceId ORDER BY ordinal ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS StartPosition
    FROM SplitWords
)
INSERT @Words
SELECT SourceId, CONVERT(int, StartPosition),
       CONVERT(int, StartPosition + WordLength - 1),
       -- Long words cannot be built-ins, but retain a sentinel to stop lookahead
       -- from skipping them and forming a false multi-word expression.
       CASE WHEN WordLength <= 128 THEN UPPER(value) ELSE N'#OVERSIZED_WORD#' END
FROM Positioned
WHERE WordLength > 0;

DECLARE @Functions TABLE
(
    Token nvarchar(128) COLLATE Latin1_General_100_CI_AS_SC PRIMARY KEY,
    Category varchar(40) NOT NULL
);
INSERT @Functions
SELECT value, 'NATIVE_DATE_TIME_FUNCTION'
FROM STRING_SPLIT(
    N'SYSDATETIMEOFFSET,SYSUTCDATETIME,SYSDATETIME,GETUTCDATE,GETDATE,CURRENT_TIMEZONE_ID,CURRENT_TIMEZONE,DATE_BUCKET,DATENAME,DATEPART,DATETRUNC,DAY,MONTH,YEAR,DATEFROMPARTS,DATETIMEFROMPARTS,DATETIME2FROMPARTS,DATETIMEOFFSETFROMPARTS,SMALLDATETIMEFROMPARTS,TIMEFROMPARTS,DATEDIFF_BIG,DATEDIFF,DATEADD,EOMONTH,SWITCHOFFSET,TODATETIMEOFFSET,ISDATE', N',');
INSERT @Functions
SELECT value, 'CONVERSION_OR_FORMAT_CANDIDATE'
FROM STRING_SPLIT(N'TRY_CAST,TRY_CONVERT,TRY_PARSE,CAST,CONVERT,PARSE,FORMAT', N',');

DECLARE @Candidates TABLE
(
    SourceId int NOT NULL,
    MatchCategory varchar(40) NOT NULL,
    Token nvarchar(128) NOT NULL,
    StartPosition int NOT NULL,
    EndPosition int NOT NULL
);
;WITH Neighbors AS
(
    SELECT *,
           LAG(Word) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS PrevWord,
           LAG(StartPosition) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS PrevStart,
           LAG(EndPosition) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS PrevEnd,
           LEAD(Word) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS NextWord,
           LEAD(StartPosition) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS NextStart,
           LEAD(EndPosition) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS NextEnd,
           LEAD(Word, 2) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS Next2Word,
           LEAD(StartPosition, 2) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS Next2Start,
           LEAD(EndPosition, 2) OVER (PARTITION BY SourceId ORDER BY StartPosition) AS Next2End
    FROM @Words
),
Interesting AS
(
    SELECT w.*, f.Category
    FROM Neighbors AS w
    LEFT JOIN @Functions AS f ON f.Token = w.Word
    WHERE f.Token IS NOT NULL OR w.Word IN
        (N'CURRENT_TIMESTAMP', N'CURRENT_DATE', N'AT', N'SET', N'TIME_ZONE',
         N'@@DATEFIRST', N'@@LANGUAGE', N'SP_HELPLANGUAGE',
         N'DATE', N'TIME', N'DATETIME', N'DATETIME2', N'DATETIMEOFFSET', N'SMALLDATETIME',
         N'CURDATE', N'CURRENT_TIME', N'CURTIME', N'DAYNAME', N'DAYOFMONTH', N'DAYOFWEEK',
         N'HOUR', N'MINUTE', N'SECOND', N'MONTHNAME', N'QUARTER', N'WEEK')
)
INSERT @Candidates
SELECT w.SourceId,
       CASE WHEN context.IsOdbc = 1 THEN 'ODBC_DATE_TIME_FUNCTION'
            WHEN w.Category IS NOT NULL AND tail.NextCharacter = N'(' THEN w.Category
            WHEN w.Word = N'AT' AND context.IsTimeZonePhrase = 1 THEN 'AT_TIME_ZONE'
            WHEN w.Word = N'SET' OR w.Word = N'TIME_ZONE' THEN 'SESSION_OR_TIME_ZONE_SETTING'
            WHEN w.Word IN (N'@@DATEFIRST', N'@@LANGUAGE', N'SP_HELPLANGUAGE') THEN 'SESSION_METADATA'
            WHEN w.Word IN (N'CURRENT_TIMESTAMP', N'CURRENT_DATE') THEN 'NATIVE_DATE_TIME_FUNCTION'
            ELSE 'DATE_TIME_TYPE_CANDIDATE' END,
       CASE WHEN context.IsOdbc = 1 THEN N'{FN ' + w.Word + N'}'
            WHEN w.Word IN (N'AT', N'SET') AND context.IsTimeZonePhrase = 1 THEN w.Word + N' TIME ZONE'
            WHEN w.Word = N'SET' THEN N'SET ' + w.NextWord
            ELSE w.Word END,
       CASE WHEN context.IsOdbc = 1 THEN gap.BeforeFnEnd ELSE w.StartPosition END,
       CASE WHEN context.IsOdbc = 1 OR (w.Category IS NOT NULL AND tail.NextCharacter = N'(')
                  OR w.Word = N'TIME_ZONE' THEN tail.NextPosition
            WHEN w.Word IN (N'AT', N'SET') AND context.IsTimeZonePhrase = 1 THEN w.Next2End
            WHEN w.Word = N'SET' THEN w.NextEnd
            ELSE w.EndPosition END
FROM Interesting AS w
JOIN @Sources AS d ON d.SourceId = w.SourceId
CROSS APPLY
(
    SELECT PATINDEX(N'%[^ ]%', SUBSTRING(d.FlatText, w.EndPosition + 1, LEN(d.FlatText + N'#'))) AS NextOffset,
           LEN(LEFT(d.FlatText, COALESCE(w.PrevStart, 1) - 1)) AS BeforeFnEnd,
           CASE WHEN LTRIM(RTRIM(SUBSTRING(d.FlatText, w.EndPosition + 1, w.NextStart - w.EndPosition - 1))) = N''
                THEN 1 ELSE 0 END AS NextIsAdjacent,
           CASE WHEN LTRIM(RTRIM(SUBSTRING(d.FlatText, w.NextEnd + 1, w.Next2Start - w.NextEnd - 1))) = N''
                THEN 1 ELSE 0 END AS Next2IsAdjacent,
           CASE WHEN LTRIM(RTRIM(SUBSTRING(d.FlatText, w.PrevEnd + 1, w.StartPosition - w.PrevEnd - 1))) = N''
                THEN 1 ELSE 0 END AS PrevIsAdjacent
) AS gap
CROSS APPLY
(
    SELECT w.EndPosition + gap.NextOffset AS NextPosition,
           CASE WHEN gap.NextOffset > 0 THEN SUBSTRING(d.FlatText, w.EndPosition + gap.NextOffset, 1) END AS NextCharacter
) AS tail
CROSS APPLY
(
    SELECT
        CASE WHEN w.PrevWord = N'FN' AND gap.PrevIsAdjacent = 1
                  AND SUBSTRING(d.FlatText, gap.BeforeFnEnd, 1) = N'{'
                  AND tail.NextCharacter = N'('
                  AND w.Word IN (N'CURRENT_DATE', N'CURDATE', N'CURRENT_TIME', N'CURTIME',
                       N'DAYNAME', N'DAYOFMONTH', N'DAYOFWEEK', N'HOUR', N'MINUTE',
                       N'SECOND', N'MONTHNAME', N'QUARTER', N'WEEK')
             THEN 1 ELSE 0 END AS IsOdbc,
        CASE WHEN w.NextWord = N'TIME' AND w.Next2Word = N'ZONE'
                  AND gap.NextIsAdjacent = 1 AND gap.Next2IsAdjacent = 1
             THEN 1 ELSE 0 END AS IsTimeZonePhrase
) AS context
WHERE context.IsOdbc = 1
   OR (w.Category IS NOT NULL AND tail.NextCharacter = N'(')
   OR w.Word IN (N'CURRENT_TIMESTAMP', N'CURRENT_DATE', N'@@DATEFIRST', N'@@LANGUAGE', N'SP_HELPLANGUAGE')
   OR (w.Word IN (N'AT', N'SET') AND context.IsTimeZonePhrase = 1)
   OR (w.Word = N'SET' AND w.NextWord IN (N'DATEFIRST', N'DATEFORMAT', N'LANGUAGE') AND gap.NextIsAdjacent = 1)
   OR (w.Word = N'TIME_ZONE' AND tail.NextCharacter = N'=')
   OR (w.Word IN (N'DATE', N'TIME', N'DATETIME', N'DATETIME2', N'DATETIMEOFFSET', N'SMALLDATETIME')
       AND NOT (w.Word = N'TIME' AND COALESCE(w.PrevWord, N'') IN (N'AT', N'SET')
                AND w.NextWord = N'ZONE' AND gap.PrevIsAdjacent = 1 AND gap.NextIsAdjacent = 1));

-- Separate quote-delimited candidates retain whole ISO/compact literals.
;WITH QuotedParts AS
(
    SELECT d.SourceId, q.ordinal, q.value,
           LEN(q.value + N'#') - 1 AS PartLength,
           COUNT_BIG(*) OVER (PARTITION BY d.SourceId) AS PartCount
    FROM @Sources AS d
    CROSS APPLY STRING_SPLIT(d.ScanText, N'''', 1) AS q
),
Positioned AS
(
    SELECT *, 1 + COALESCE(SUM(PartLength + 1) OVER
        (PARTITION BY SourceId ORDER BY ordinal ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS StartPosition
    FROM QuotedParts
)
INSERT @Candidates
SELECT q.SourceId, 'DATE_TIME_LITERAL_CANDIDATE',
       LEFT(UPPER(N'''' + q.value + N''''), 128),
       CONVERT(int, q.StartPosition - 1),
       CONVERT(int, q.StartPosition + q.PartLength)
FROM Positioned AS q
WHERE q.ordinal > 1 AND q.ordinal < q.PartCount
  AND q.PartLength BETWEEN 5 AND 40
  AND q.value COLLATE Latin1_General_100_BIN2 NOT LIKE N'%[^0-9TtZz:+. -]%'
  AND ((q.PartLength = 8 AND q.value COLLATE Latin1_General_100_BIN2 NOT LIKE N'%[^0-9]%')
       OR q.value LIKE N'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]%'
       OR q.value LIKE N'[0-9][0-9]:[0-9][0-9]%');

DECLARE @Matches TABLE
(
    SourceId int NOT NULL,
    MatchId bigint NOT NULL,
    MatchCategory varchar(40) NOT NULL,
    Token nvarchar(128) NOT NULL,
    MatchedText nvarchar(max) NULL,
    StartPosition int NOT NULL,
    EndPosition int NOT NULL,
    StartLineNumber int NOT NULL,
    EndLineNumber int NOT NULL,
    ColumnNumber int NOT NULL,
    SourceLine nvarchar(4000) NULL,
    IsSourceLineTruncated bit NOT NULL,
    PRIMARY KEY (SourceId, MatchId)
);

INSERT @Matches
SELECT c.SourceId,
       ROW_NUMBER() OVER (PARTITION BY c.SourceId ORDER BY c.StartPosition, c.EndPosition, c.MatchCategory),
       c.MatchCategory, c.Token, SUBSTRING(d.ScanText, c.StartPosition, c.EndPosition - c.StartPosition + 1),
       c.StartPosition, c.EndPosition, startLine.LineNumber, endLine.LineNumber,
       c.StartPosition - startLine.StartPosition + 1,
       startLine.SourceLine, CONVERT(bit, CASE WHEN startLine.LineLength > 4000 THEN 1 ELSE 0 END)
FROM @Candidates AS c
JOIN @Sources AS d ON d.SourceId = c.SourceId
JOIN @Lines AS startLine ON startLine.SourceId = c.SourceId
    AND c.StartPosition BETWEEN startLine.StartPosition AND startLine.StartPosition + startLine.LineLength
JOIN @Lines AS endLine ON endLine.SourceId = c.SourceId
    AND c.EndPosition BETWEEN endLine.StartPosition AND endLine.StartPosition + endLine.LineLength;

-- 1: scope and limitations. This row is returned even for an empty database.
SELECT DB_NAME() AS DatabaseName, COALESCE(@DiscoverySchema, N'(all visible user schemas)') AS SchemaScope,
       @HasViewDefinition AS HasDatabaseViewDefinition,
       (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()) AS CompatibilityLevel,
       (SELECT COUNT(*) FROM @Sources) AS VisibleArtifactCount,
       (SELECT COUNT(*) FROM @Sources WHERE ScanStatus = 'SCANNED') AS ScannedArtifactCount,
       (SELECT COUNT(*) FROM @Sources WHERE ScanStatus <> 'SCANNED') AS UnscannedArtifactCount,
       (SELECT COUNT(*) FROM @Matches) AS CandidateOccurrenceCount,
       N'Text candidates, not semantic proof; comments and strings retained. See batch header for visibility and scope limits.' AS Interpretation;

-- 2: every discovered source class, including zero-match classes.
;WITH Occurrences AS
(
    SELECT SourceId, COUNT_BIG(*) AS MatchCount FROM @Matches GROUP BY SourceId
)
SELECT d.ObjectType, d.ArtifactType, COUNT(*) AS VisibleArtifacts,
       SUM(CASE WHEN d.ScanStatus = 'SCANNED' THEN 1 ELSE 0 END) AS ScannedArtifacts,
       SUM(CASE WHEN o.MatchCount > 0 THEN 1 ELSE 0 END) AS MatchedArtifacts,
       SUM(CASE WHEN d.ScanStatus = 'SCANNED' AND o.MatchCount IS NULL THEN 1 ELSE 0 END) AS ScannedWithoutMatches,
       SUM(CASE WHEN d.ScanStatus <> 'SCANNED' THEN 1 ELSE 0 END) AS UnscannedArtifacts,
       SUM(COALESCE(o.MatchCount, 0)) AS CandidateOccurrences
FROM @Sources AS d
LEFT JOIN Occurrences AS o ON o.SourceId = d.SourceId
GROUP BY d.ObjectType, d.ArtifactType
ORDER BY d.ObjectType, d.ArtifactType;

-- 3: artifact inventory. A table can have multiple computed/index artifacts.
SELECT d.SourceId, d.ObjectType, d.SchemaName, d.ObjectName, d.ParentObject,
       d.ArtifactType, d.ArtifactName, d.ColumnName, d.IsDisabled, d.IsNotTrusted,
       COUNT_BIG(*) AS CandidateOccurrences,
       COUNT(DISTINCT m.Token) AS DistinctTokens,
       SUM(CASE WHEN m.MatchCategory IN ('NATIVE_DATE_TIME_FUNCTION', 'ODBC_DATE_TIME_FUNCTION') THEN 1 ELSE 0 END) AS DateTimeFunctions,
       SUM(CASE WHEN m.MatchCategory = 'AT_TIME_ZONE' THEN 1 ELSE 0 END) AS AtTimeZoneExpressions,
       SUM(CASE WHEN m.MatchCategory = 'CONVERSION_OR_FORMAT_CANDIDATE' THEN 1 ELSE 0 END) AS ConversionCandidates,
       SUM(CASE WHEN m.MatchCategory = 'DATE_TIME_TYPE_CANDIDATE' THEN 1 ELSE 0 END) AS TypeCandidates,
       SUM(CASE WHEN m.MatchCategory = 'DATE_TIME_LITERAL_CANDIDATE' THEN 1 ELSE 0 END) AS LiteralCandidates,
       SUM(CASE WHEN m.MatchCategory IN ('SESSION_METADATA', 'SESSION_OR_TIME_ZONE_SETTING') THEN 1 ELSE 0 END) AS SessionExpressions
FROM @Sources AS d
JOIN @Matches AS m ON m.SourceId = d.SourceId
GROUP BY d.SourceId, d.ObjectType, d.SchemaName, d.ObjectName, d.ParentObject,
         d.ArtifactType, d.ArtifactName, d.ColumnName, d.IsDisabled, d.IsNotTrusted
ORDER BY d.ObjectType, d.SchemaName, d.ObjectName, d.ArtifactType, d.ArtifactName;

-- 4: one row per occurrence; multiple matches on the same line stay separate.
SELECT d.SourceId, d.ObjectType, d.SchemaName, d.ObjectName, d.ParentObject,
       d.ArtifactType, d.ArtifactName, d.ColumnName,
       CASE WHEN d.IsModule = 1 THEN N'MODULE_DEFINITION' ELSE N'CATALOG_EXPRESSION' END AS LineNumberBasis,
       m.MatchId, m.MatchCategory, m.Token, m.MatchedText,
       m.StartLineNumber AS LineNumber, m.EndLineNumber, m.ColumnNumber,
       m.StartPosition, m.EndPosition, m.SourceLine, m.IsSourceLineTruncated
FROM @Sources AS d
JOIN @Matches AS m ON m.SourceId = d.SourceId
ORDER BY d.ObjectType, d.SchemaName, d.ObjectName, d.ArtifactType, d.ArtifactName, m.MatchId;

-- 5: authoritative type bindings, including aliases based on a date/time type.
;WITH TypeBindings AS
(
    SELECT o.ObjectType, o.SchemaName, o.ObjectName,
           CASE WHEN o.ObjectType = N'USER_TABLE_TYPE' THEN N'TABLE_TYPE_COLUMN' ELSE N'COLUMN' END AS UsageKind,
           c.name AS MemberName, c.column_id AS MemberId,
           c.system_type_id, c.user_type_id, c.precision, c.scale,
           c.is_nullable AS IsNullable, c.is_computed AS IsComputed
    FROM sys.columns AS c
    JOIN @ObjectCatalog AS o ON o.ObjectId = c.object_id
    WHERE c.system_type_id IN (40, 41, 42, 43, 58, 61)
    UNION ALL
    SELECT o.ObjectType, o.SchemaName, o.ObjectName,
           CASE WHEN p.parameter_id = 0 THEN N'SCALAR_RETURN_TYPE' ELSE N'PARAMETER' END,
           p.name, p.parameter_id, p.system_type_id, p.user_type_id,
           p.precision, p.scale, CAST(NULL AS bit), CAST(NULL AS bit)
    FROM sys.parameters AS p
    JOIN @ObjectCatalog AS o ON o.ObjectId = p.object_id
    WHERE p.system_type_id IN (40, 41, 42, 43, 58, 61)
)
SELECT b.ObjectType, b.SchemaName, b.ObjectName, b.UsageKind, b.MemberName, b.MemberId,
       TYPE_NAME(b.system_type_id) AS BaseDateTimeType,
       CASE WHEN t.is_user_defined = 1 THEN QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' ELSE N'' END
           + QUOTENAME(t.name) AS DeclaredType,
       b.precision, b.scale, b.IsNullable, b.IsComputed
FROM TypeBindings AS b
JOIN sys.types AS t ON t.user_type_id = b.user_type_id
ORDER BY b.ObjectType, b.SchemaName, b.ObjectName, b.UsageKind, b.MemberId;

-- 6: explicit gaps. NULL definitions do not mean "no date/time usage".
SELECT ObjectType, SchemaName, ObjectName, ParentObject, ArtifactType, ArtifactName,
       ColumnName, IsEncrypted, DefinitionBytes, ScanStatus
FROM @Sources
WHERE ScanStatus <> 'SCANNED'
ORDER BY ObjectType, SchemaName, ObjectName, ArtifactType, ArtifactName;
GO
