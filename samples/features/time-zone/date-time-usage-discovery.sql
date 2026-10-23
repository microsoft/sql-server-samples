/*
This script will work only on Azure SQL Database, Azure SQL Managed Instance (Always-up-to-date & SQL Server 2025 policy), SQL Server 2025 or above.
*/
DECLARE @EngineEdition int =
    COALESCE(CONVERT(int, SERVERPROPERTY('EngineEdition')), 0);

DECLARE @MajorVersion int =
    COALESCE(TRY_CONVERT(int, SERVERPROPERTY('ProductMajorVersion')), 0);

DECLARE @UpdateType nvarchar(128) =
    COALESCE(CONVERT(nvarchar(128), SERVERPROPERTY('ProductUpdateType')), N'');

IF NOT
(
    -- Azure SQL Database
    @EngineEdition = 5

    -- Azure SQL Managed Instance: Always-up-to-date or SQL Server 2025 policy
    OR
    (
        @EngineEdition = 8
        AND
        (
            @UpdateType = N'Continuous'
            OR (@UpdateType = N'CU' AND @MajorVersion = 17)
        )
    )

    -- SQL Server 2025 (17.x) or later: Standard, Enterprise/Developer, Express
    OR
    (
        @EngineEdition IN (2, 3, 4)
        AND @MajorVersion >= 17
    )
)
BEGIN
    THROW 50000,
        'Unsupported platform. Requires Azure SQL Database, Azure SQL Managed Instance with Always-up-to-date or SQL Server 2025 update policy, or SQL Server 2025 (17.x) or later.',
        1;
END;
go

/* ============================================================================
DATE/TIME DISCOVERY - independent, read-only batch

Select everything from this comment through the final GO to inspect an existing
database. It uses catalog views only; it does not depend on DateTimeLab objects.
NULL scans all visible user schemas and database-scoped DDL triggers.
Set @DiscoverySchema = N'DateTimeLab' to restrict the report to the fixture.

Result sets:
  1. Scope, permissions, scanned-source counts, and inspection limitations.
  2. Summary by object type and artifact type, including sources with no matches.
  3. One row per matched artifact: parent/column/index and category totals.
  4. Every regex occurrence: token, category, line/column, and source-line text.
  5. Actual date/time columns, UDF return types, and procedure/UDF parameters,
     including alias types. These are catalog-confirmed, not regex guesses.
  6. Objects/expressions whose definitions could not be scanned.

The regex scans SQL TEXT, not a parsed syntax tree. It deliberately retains
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
are not treated as whitespace by these regex patterns and can prevent a match.

Line 1 is the first line of sys.sql_modules.definition, not the original script
file. Expression line numbers are relative to the catalog expression. CRLF and
lone CR are normalized to LF; character offsets refer to that normalized text.
SC collation keeps Unicode supplementary-character offsets consistent.
Line text is capped at 4,000 characters with an explicit truncation indicator.
Definitions exceeding the documented 2 MB regex input limit are reported as gaps
without truncating/scanning a partial definition. VIEW DEFINITION is recommended;
catalog rows invisible to the caller cannot be listed, even in the gaps report.

https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-matches-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-count-transact-sql
============================================================================ */

SET NOCOUNT ON;
DECLARE @DiscoverySchema sysname = NULL;
DECLARE @RegexMaxBytes int = 2097152;
DECLARE @HasViewDefinition bit =
    CASE WHEN HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') = 1
         THEN 1 ELSE 0 END;

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
    ScanText nvarchar(max) COLLATE Latin1_General_100_CI_AS_SC NULL
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
         WHEN DefinitionBytes > @RegexMaxBytes THEN 'EXCEEDS_REGEX_2MB_LIMIT'
         ELSE 'SCANNED' END,
    ScanText = CASE WHEN DefinitionBytes <= @RegexMaxBytes
                   THEN REPLACE(REPLACE(ScanText, NCHAR(13) + NCHAR(10), NCHAR(10)), NCHAR(13), NCHAR(10))
                   END;

-- ODBC signatures come first so {fn CURRENT_DATE()} is not counted twice.
-- Function-call patterns require '(' but allow intervening line breaks.
DECLARE @DateTimePattern nvarchar(4000) =
    N'\{\s*fn\s+(?:CURRENT_DATE|CURDATE|CURRENT_TIME|CURTIME|DAYNAME|DAYOFMONTH|DAYOFWEEK|HOUR|MINUTE|SECOND|MONTHNAME|QUARTER|WEEK)\s*\('
  + N'|\b(?:SYSDATETIMEOFFSET|SYSUTCDATETIME|SYSDATETIME|GETUTCDATE|GETDATE|CURRENT_TIMEZONE_ID|CURRENT_TIMEZONE'
  + N'|DATE_BUCKET|DATENAME|DATEPART|DATETRUNC|DAY|MONTH|YEAR'
  + N'|DATEFROMPARTS|DATETIMEFROMPARTS|DATETIME2FROMPARTS|DATETIMEOFFSETFROMPARTS|SMALLDATETIMEFROMPARTS|TIMEFROMPARTS'
  + N'|DATEDIFF_BIG|DATEDIFF|DATEADD|EOMONTH|SWITCHOFFSET|TODATETIMEOFFSET|ISDATE'
  + N'|TRY_CAST|TRY_CONVERT|TRY_PARSE|CAST|CONVERT|PARSE|FORMAT)\s*\('
  + N'|\b(?:CURRENT_TIMESTAMP|CURRENT_DATE)\b'
  + N'|@@(?:DATEFIRST|LANGUAGE)\b'
  + N'|\bAT\s+TIME\s+ZONE\b'
  + N'|\bSET\s+(?:TIME\s+ZONE|DATEFIRST|DATEFORMAT|LANGUAGE)\b'
  + N'|\bTIME_ZONE\s*='
  + N'|\bsp_helplanguage\b'
  + N'|N?''(?:[0-9]{4}-[0-9]{2}-[0-9]{2}(?:[T ][0-9]{2}:[0-9]{2}(?::[0-9]{2}(?:\.[0-9]{1,7})?)?(?:Z|[+-][0-9]{2}:[0-9]{2})?)?|[0-9]{8}|[0-9]{2}:[0-9]{2}(?::[0-9]{2}(?:\.[0-9]{1,7})?)?)'''
  + N'|\b(?:datetimeoffset|datetime2|smalldatetime|datetime|date|time)\b';

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
SELECT d.SourceId, m.match_id,
       CASE WHEN REGEXP_LIKE(m.match_value, N'^\{', 'i') THEN 'ODBC_DATE_TIME_FUNCTION'
            WHEN REGEXP_LIKE(m.match_value, N'^N?''', 'i') THEN 'DATE_TIME_LITERAL_CANDIDATE'
            WHEN REGEXP_LIKE(m.match_value, N'^(TRY_CAST|TRY_CONVERT|TRY_PARSE|CAST|CONVERT|PARSE|FORMAT)\s*\(', 'i')
                THEN 'CONVERSION_OR_FORMAT_CANDIDATE'
            WHEN REGEXP_LIKE(m.match_value, N'^AT\s+TIME\s+ZONE$', 'i') THEN 'AT_TIME_ZONE'
            WHEN REGEXP_LIKE(m.match_value, N'^SET\s|^TIME_ZONE\s*=', 'i') THEN 'SESSION_OR_TIME_ZONE_SETTING'
            WHEN REGEXP_LIKE(m.match_value, N'^@@|^sp_helplanguage$', 'i') THEN 'SESSION_METADATA'
            WHEN REGEXP_LIKE(m.match_value, N'^(date|time|datetime|datetime2|datetimeoffset|smalldatetime)$', 'i')
                THEN 'DATE_TIME_TYPE_CANDIDATE'
            ELSE 'NATIVE_DATE_TIME_FUNCTION' END,
       UPPER(CASE WHEN REGEXP_LIKE(m.match_value, N'^\{', 'i')
                  THEN N'{fn ' + REGEXP_SUBSTR(m.match_value, N'[A-Z_][A-Z_0-9]*', 1, 2, 'i') + N'}'
                  ELSE RTRIM(REGEXP_REPLACE(REGEXP_REPLACE(m.match_value, N'\s+', N' '), N'[ (=]+$', N'')) END),
       m.match_value, m.start_position, m.end_position,
       loc.StartLineNumber, loc.StartLineNumber + REGEXP_COUNT(m.match_value, N'\n'),
       loc.ColumnNumber,
       LEFT(SUBSTRING(d.ScanText, loc.LineStartPosition, line.Length), 4000),
       CONVERT(bit, CASE WHEN line.Length > 4000 THEN 1 ELSE 0 END)
FROM @Sources AS d
CROSS APPLY REGEXP_MATCHES(COALESCE(d.ScanText, N''), @DateTimePattern, 'i') AS m
CROSS APPLY
(
    SELECT COALESCE(LEN(REGEXP_SUBSTR(LEFT(d.ScanText, m.start_position - 1), N'[^\n]*$') + N'#') - 1, 0) AS PrefixLength
) AS prefix
CROSS APPLY
(
    SELECT 1 + REGEXP_COUNT(LEFT(d.ScanText, m.start_position - 1), N'\n') AS StartLineNumber,
           prefix.PrefixLength + 1 AS ColumnNumber,
           m.start_position - prefix.PrefixLength AS LineStartPosition
) AS loc
CROSS APPLY
(
    SELECT CHARINDEX(NCHAR(10), d.ScanText + NCHAR(10), loc.LineStartPosition) - loc.LineStartPosition AS Length
) AS line
WHERE (m.start_position = 1 OR NOT REGEXP_LIKE(
           SUBSTRING(d.ScanText, m.start_position - 1, 1), N'[\p{L}\p{N}_@$#]'))
  AND NOT (REGEXP_LIKE(RIGHT(m.match_value, 1), N'[A-Z0-9_]', 'i')
       AND REGEXP_LIKE(SUBSTRING(d.ScanText, m.end_position + 1, 1), N'[\p{L}\p{N}_@$#]'));

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
