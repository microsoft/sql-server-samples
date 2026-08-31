/*======================================================================================
Script: aspstate_sql2016_with_retry.sql

Description:
This script is based on the InstallSqlState.sql script but works with SQL 2016 In-Memory OLTP by replacing the following objects
to in-memory and natively compiled stored procedures.

** Tables:
	Converted the following table to In-Memory table:
		- [dbo].[ASPStateTempSessions] (SessionId: NONCLUSTERED HASH PK (Bucket Count=33554432))

** Stored Procedures:
	Converted the following SPs to Native Compiled SPs:
		- dbo.TempGetStateItemExclusive3
		- dbo.TempInsertStateItemShort
	        - dbo.TempUpdateStateItemLong
	        - dbo.TempUpdateStateItemLongNullShort
	        - dbo.TempUpdateStateItemShort

Warning:		
This script may fail if you have any DDL triggers on create, update or delete tables. This type of trigger is often used
with solutions that monitor database changes e.g. source control integration & schema monitors.

Global triggers can be found under Server Objects->Triggers in SSMS
	
======================================================================================*/

USE [master]
GO

DECLARE @SQLDataFolder nvarchar(max) = cast(SERVERPROPERTY('InstanceDefaultDataPath') as nvarchar(max))
DECLARE @SQLLogFolder nvarchar(max) = cast(SERVERPROPERTY('InstanceDefaultLogPath') as nvarchar(max))
DECLARE @SQL nvarchar(max) = N'';

SET @SQL = N'
CREATE DATABASE [ASPState]
 CONTAINMENT = NONE
 ON  PRIMARY
	(NAME = N''ASPState'', FILENAME = N''' + @SQLDataFolder + 'ASPState.mdf'' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ),
 FILEGROUP [ASPState_mod] CONTAINS MEMORY_OPTIMIZED_DATA  DEFAULT
	(NAME = N''ASPState_mod'', FILENAME = N''' + @SQLLogFolder + 'ASPState_mod'' , MAXSIZE = UNLIMITED)
 LOG ON
	(NAME = N''ASPState_log'', FILENAME = N''' + @SQLLogFolder + 'ASPState_log.ldf'' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB );

ALTER DATABASE [ASPState] SET COMPATIBILITY_LEVEL = 130; ALTER DATABASE [ASPState] SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON;'

EXECUTE (@SQL)
GO

USE [AspState]
GO

CREATE ROLE [ASPStateExecute];
CREATE ROLE [ASPStateResetRole];
CREATE ROLE [ASPStateRole];

CREATE TYPE [dbo].[tAppName] FROM [varchar](280) NOT NULL;
CREATE TYPE [dbo].[tSessionId] FROM [nvarchar](88) NOT NULL;
CREATE TYPE [dbo].[tSessionItemLong] FROM [image] NULL;
CREATE TYPE [dbo].[tSessionItemShort] FROM [varbinary](7000) NULL;
CREATE TYPE [dbo].[tTextPtr] FROM [varbinary](max) NULL;


CREATE TABLE [dbo].[ASPStateTempSessions]
(
	[SessionId] [nvarchar](88) COLLATE Latin1_General_100_BIN2 NOT NULL,
	[Created] [datetime] NOT NULL DEFAULT (getutcdate()),
	[Expires] [datetime] NOT NULL,
	[LockDate] [datetime] NOT NULL,
	[LockDateLocal] [datetime] NOT NULL,
	[LockCookie] [int] NOT NULL,
	[Timeout] [int] NOT NULL,
	[Locked] [bit] NOT NULL,
	[SessionItemShort] [varbinary](7000) NULL,
	[SessionItemLong] [varbinary](max) NULL,
	[Flags] [int] NOT NULL DEFAULT ((0)),

INDEX [Index_Expires] NONCLUSTERED
(
	[Expires] ASC
),
PRIMARY KEY NONCLUSTERED HASH
(
	[SessionId]
)WITH ( BUCKET_COUNT = 33554432)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY )
GO

CREATE TABLE [dbo].[ASPStateTempApplications](
	[AppId] [int] NOT NULL,
	[AppName] [char](280) NOT NULL,
PRIMARY KEY CLUSTERED
(
	[AppId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE PROCEDURE [dbo].[TempGetStateItemExclusive3_HK]
			@id         nvarchar(88),
            @itemShort  varbinary(7000) OUTPUT,
            @locked     bit OUTPUT,
            @lockAge    int OUTPUT,
            @lockCookie int OUTPUT,
            @actionFlags int OUTPUT
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

    DECLARE @textptr AS varbinary(max)
    DECLARE @length AS int
    DECLARE @now AS datetime
    DECLARE @nowLocal AS datetime

    SET @now = GETUTCDATE()
    SET @nowLocal = GETDATE()
	
	DECLARE @LockedCheck bit
	DECLARE @Flags int

	SELECT @LockedCheck=Locked, @Flags=Flags FROM dbo.ASPStateTempSessions WHERE SessionID=@id
		
	IF @Flags&1 <> 0
	BEGIN
		SET @actionFlags=1
		UPDATE dbo.ASPStateTempSessions SET Flags=Flags& ~1 WHERE SessionID=@id
	END
	ELSE
		SET @actionFlags=0

	IF @LockedCheck=1
	BEGIN
		UPDATE dbo.ASPStateTempSessions
        SET Expires = DATEADD(n, Timeout, @now),
            @lockAge = DATEDIFF(second, LockDate, @now),
            @lockCookie = LockCookie,
            @itemShort = NULL,
            --@textptr = NULL,
            @length = NULL,
            @locked = 1
        WHERE SessionId = @id
	END
	ELSE
	BEGIN
		UPDATE dbo.ASPStateTempSessions
        SET Expires = DATEADD(n, Timeout, @now),
            LockDate = @now,
            LockDateLocal = @nowlocal,
            @lockAge = 0,
            @lockCookie = LockCookie = LockCookie + 1,
            @itemShort = SessionItemShort,
            @textptr = SessionItemLong,
            @length = 1,
            @locked = 0,
            Locked = 1
        WHERE SessionId = @id

		IF @TextPtr IS NOT NULL
			SELECT @TextPtr
		
	END
END
GO

CREATE PROCEDURE [dbo].[TempGetStateItemExclusive3]
			@id         nvarchar(88),
            @itemShort  varbinary(7000) OUTPUT,
            @locked     bit OUTPUT,
            @lockAge    int OUTPUT,
            @lockCookie int OUTPUT,
            @actionFlags int OUTPUT
AS
BEGIN
    DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				EXEC dbo.TempGetStateItemExclusive3_HK
					 @id,
					 @itemShort = @itemShort OUTPUT,
					 @locked = @locked OUTPUT,
					 @lockAge = @lockAge OUTPUT,
					 @lockCookie = @lockCookie OUTPUT,
					 @actionFlags = @actionFlags OUTPUT
									
            COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
END;
GO

CREATE PROCEDURE [dbo].[TempInsertStateItemShort_HK]
	@id	nvarchar(88),
	@itemShort varbinary(7000),
	@timeout int
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

	DECLARE @now AS datetime
	DECLARE @nowLocal AS datetime

	SET @now = GETUTCDATE()
	SET @nowLocal = GETDATE()

	INSERT dbo.ASPStateTempSessions
		(SessionId,
		SessionItemShort,
		Timeout,
		Expires,
		Locked,
		LockDate,
		LockDateLocal,
		LockCookie,
		Created,
		Flags,
		SessionItemLong)
	VALUES
		(@id,
		@itemShort,
		@timeout,
		DATEADD(n, @timeout, @now),
		0,
		@now,
		@nowLocal,
		1,
		@now,
		0,
		NULL)

	RETURN 0
END
GO

CREATE PROCEDURE [dbo].[TempInsertStateItemShort]
	@id	nvarchar(88),
	@itemShort varbinary(7000),
	@timeout int
AS
BEGIN
    DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				EXEC dbo.TempInsertStateItemShort_HK @id, @itemShort, @timeout
									
            COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
END;
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemLong_HK]
    @id         nvarchar(88),
    @itemLong   varbinary(max),
    @timeout    int,
    @lockCookie int
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

	UPDATE	dbo.ASPStateTempSessions
    SET		Expires = DATEADD(n, @timeout, GETUTCDATE()),
            SessionItemLong = @itemLong,
            Timeout = @timeout,
            Locked = 0
    WHERE	SessionId = @id AND LockCookie = @lockCookie

	RETURN 0
END
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemLong]
    @id         nvarchar(88),
    @itemLong   varbinary(max),
    @timeout    int,
    @lockCookie int
AS
BEGIN
    DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				EXEC dbo.TempUpdateStateItemLong_HK @id, @itemLong, @timeout, @lockCookie
									
            COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
END;
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemLongNullShort_HK]
    @id         nvarchar(88),
    @itemLong   varbinary(max),
    @timeout    int,
    @lockCookie int
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

    UPDATE	dbo.ASPStateTempSessions
    SET		Expires = DATEADD(n, @timeout, GETUTCDATE()),
			SessionItemLong = @itemLong,
			SessionItemShort = NULL,
			Timeout = @timeout,
			Locked = 0
    WHERE	SessionId = @id AND LockCookie = @lockCookie

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemLongNullShort]
    @id         nvarchar(88),
    @itemLong   varbinary(max),
    @timeout    int,
    @lockCookie int
AS
BEGIN
    DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				EXEC dbo.TempUpdateStateItemLongNullShort_HK @id, @itemLong, @timeout, @lockCookie
									
            COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
END;
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemShort_HK]
    @id         nvarchar(88),
    @itemShort  varbinary(7000),
    @timeout    int,
    @lockCookie int
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english' )

    UPDATE	dbo.ASPStateTempSessions
    SET		Expires = DATEADD(n, @timeout, GETUTCDATE()),
			SessionItemShort = @itemShort,
			Timeout = @timeout,
			Locked = 0
    WHERE	SessionId = @id AND LockCookie = @lockCookie

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemShort]
    @id         nvarchar(88),
    @itemShort   varbinary(max),
    @timeout    int,
    @lockCookie int
AS
BEGIN
    DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				EXEC dbo.TempUpdateStateItemShort_HK @id, @itemShort, @timeout, @lockCookie
									
            COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
END;
GO

CREATE PROCEDURE [dbo].[CreateTempTables]
AS
    CREATE TABLE ASPStateTempSessions (
        SessionId           nvarchar(88)    COLLATE Latin1_General_100_BIN2 NOT NULL,
        Created             datetime        NOT NULL DEFAULT GETUTCDATE(),
        Expires             datetime        NOT NULL,
        LockDate            datetime        NOT NULL,
        LockDateLocal       datetime        NOT NULL,
        LockCookie          int             NOT NULL,
        Timeout             int             NOT NULL,
        Locked              bit             NOT NULL,
        SessionItemShort    VARBINARY(7000) NULL,
        SessionItemLong     VARBINARY(max)  NULL,
        Flags               int             NOT NULL DEFAULT 0,

		PRIMARY KEY NONCLUSTERED HASH
		(
			[SessionId]
		)WITH ( BUCKET_COUNT = 33554432),
		INDEX Index_Expires (Expires)

	)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY )
			
    CREATE TABLE dbo.ASPStateTempApplications (
        AppId               int             NOT NULL PRIMARY KEY,
        AppName             char(280)       NOT NULL,
    )
    CREATE NONCLUSTERED INDEX Index_AppName ON ASPStateTempApplications(AppName)

RETURN 0
GO

CREATE PROCEDURE [dbo].[DeleteExpiredSessions]
AS
    SET NOCOUNT ON
    SET DEADLOCK_PRIORITY LOW

    DECLARE @now datetime
    SET @now = GETUTCDATE()

    CREATE TABLE #tblExpiredSessions
    (
        SessionId nvarchar(88) NOT NULL PRIMARY KEY
    )

    INSERT #tblExpiredSessions (SessionId)
        SELECT SessionId
        FROM ASPStateTempSessions WITH (SNAPSHOT)
        WHERE Expires < @now

    IF @@ROWCOUNT <> 0
    BEGIN
        DECLARE ExpiredSessionCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT SessionId FROM #tblExpiredSessions

        DECLARE @SessionId nvarchar(88)

        OPEN ExpiredSessionCursor

        FETCH NEXT FROM ExpiredSessionCursor INTO @SessionId

        WHILE @@FETCH_STATUS = 0
            BEGIN
                DELETE FROM ASPStateTempSessions WHERE SessionId = @SessionId AND Expires < @now
                FETCH NEXT FROM ExpiredSessionCursor INTO @SessionId
            END

        CLOSE ExpiredSessionCursor

        DEALLOCATE ExpiredSessionCursor

    END

    DROP TABLE #tblExpiredSessions

RETURN 0
GO

CREATE PROCEDURE [dbo].[GetHashCode]
    @input tAppName,
    @hash int OUTPUT
AS
    /*
       This sproc is based on this C# hash function:

        int GetHashCode(string s)
        {
            int     hash = 5381;
            int     len = s.Length;

            for (int i = 0; i < len; i++) {
                int     c = Convert.ToInt32(s[i]);
                hash = ((hash << 5) + hash) ^ c;
            }

            return hash;
        }

        However, SQL 7 doesn't provide a 32-bit integer
        type that allows rollover of bits, we have to
        divide our 32bit integer into the upper and lower
        16 bits to do our calculation.
    */

    DECLARE @hi_16bit   int
    DECLARE @lo_16bit   int
    DECLARE @hi_t       int
    DECLARE @lo_t       int
    DECLARE @len        int
    DECLARE @i          int
    DECLARE @c          int
    DECLARE @carry      int

    SET @hi_16bit = 0
    SET @lo_16bit = 5381

    SET @len = DATALENGTH(@input)
    SET @i = 1

    WHILE (@i <= @len)
    BEGIN
        SET @c = ASCII(SUBSTRING(@input, @i, 1))

        /* Formula:
           hash = ((hash << 5) + hash) ^ c */

        /* hash << 5 */
        SET @hi_t = @hi_16bit * 32 /* high 16bits << 5 */
        SET @hi_t = @hi_t & 0xFFFF /* zero out overflow */

        SET @lo_t = @lo_16bit * 32 /* low 16bits << 5 */

        SET @carry = @lo_16bit & 0x1F0000 /* move low 16bits carryover to hi 16bits */
        SET @carry = @carry / 0x10000 /* >> 16 */
        SET @hi_t = @hi_t + @carry
        SET @hi_t = @hi_t & 0xFFFF /* zero out overflow */

        /* + hash */
        SET @lo_16bit = @lo_16bit + @lo_t
        SET @hi_16bit = @hi_16bit + @hi_t + (@lo_16bit / 0x10000)
        /* delay clearing the overflow */

        /* ^c */
        SET @lo_16bit = @lo_16bit ^ @c

        /* Now clear the overflow bits */	
        SET @hi_16bit = @hi_16bit & 0xFFFF
        SET @lo_16bit = @lo_16bit & 0xFFFF

        SET @i = @i + 1
    END

    /* Do a sign extension of the hi-16bit if needed */
    IF (@hi_16bit & 0x8000 <> 0)
        SET @hi_16bit = 0xFFFF0000 | @hi_16bit

    /* Merge hi and lo 16bit back together */
    SET @hi_16bit = @hi_16bit * 0x10000 /* << 16 */
    SET @hash = @hi_16bit | @lo_16bit

    RETURN 0

GO

CREATE PROCEDURE [dbo].[GetMajorVersion]
    @@ver int OUTPUT
AS
BEGIN
    DECLARE @version        nchar(100)
    DECLARE @dot            int
    DECLARE @hyphen         int
    DECLARE @SqlToExec      nchar(4000)

    SELECT @@ver = 7
    SELECT @version = @@Version
    SELECT @hyphen  = CHARINDEX(N' - ', @version)
    IF (NOT(@hyphen IS NULL) AND @hyphen > 0)
    BEGIN
            SELECT @hyphen = @hyphen + 3
            SELECT @dot    = CHARINDEX(N'.', @version, @hyphen)
            IF (NOT(@dot IS NULL) AND @dot > @hyphen)
            BEGIN
                    SELECT @version = SUBSTRING(@version, @hyphen, @dot - @hyphen)
                    SELECT @@ver     = CONVERT(int, @version)
            END
    END
END
GO

CREATE PROCEDURE [dbo].[TempGetAppID]
	@appName	VARCHAR(280), --@appName    tAppName,
	@appId      int OUTPUT
AS
	SET @appName = LOWER(@appName)
	SET @appId = NULL

	SELECT @appId = AppId
	FROM ASPStateTempApplications
	WHERE AppName = @appName

	IF @appId IS NULL BEGIN
		BEGIN TRAN

		SELECT @appId = AppId
		FROM ASPStateTempApplications WITH (TABLOCKX)
		WHERE AppName = @appName

		IF @appId IS NULL
		BEGIN
			EXEC GetHashCode @appName, @appId OUTPUT

			INSERT ASPStateTempApplications
			VALUES
			(@appId, @appName)

			IF @@ERROR = 2627
			BEGIN
				DECLARE @dupApp tAppName

				SELECT @dupApp = RTRIM(AppName)
				FROM ASPStateTempApplications
				WHERE AppId = @appId

				RAISERROR('SQL session state fatal error: hash-code collision between applications ''%s'' and ''%s''. Please rename the 1st application to resolve the problem.',
							18, 1, @appName, @dupApp)
			END
		END
		COMMIT
	END

RETURN 0

GO

CREATE PROCEDURE [dbo].[TempGetStateItem]
    @id         tSessionId,
    @itemShort  tSessionItemShort OUTPUT,
    @locked     bit OUTPUT,
    @lockDate   datetime OUTPUT,
    @lockCookie int OUTPUT
AS
    DECLARE @textptr AS tTextPtr
    DECLARE @length AS int
    DECLARE @now AS datetime
    SET @now = GETUTCDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

				UPDATE ASPStateTempSessions
				SET Expires = DATEADD(n, Timeout, @now),
					@locked = Locked,
					@lockDate = LockDateLocal,
					@lockCookie = LockCookie,
					@itemShort = CASE @locked
						WHEN 0 THEN SessionItemShort
						ELSE NULL
						END,
					@textptr = CASE @locked
						WHEN 0 THEN SessionItemLong
						ELSE NULL
						END,
					@length = CASE @locked
						WHEN 0 THEN DATALENGTH(SessionItemLong)
						ELSE NULL
						END
				WHERE SessionId = @id
				IF @length IS NOT NULL BEGIN
					SELECT @textptr
				END
				COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempGetStateItem2]
    @id         tSessionId,
    @itemShort  tSessionItemShort OUTPUT,
    @locked     bit OUTPUT,
    @lockAge    int OUTPUT,
    @lockCookie int OUTPUT
AS
    DECLARE @textptr AS tTextPtr
    DECLARE @length AS int
    DECLARE @now AS datetime
    SET @now = GETUTCDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE ASPStateTempSessions
				SET Expires = DATEADD(n, Timeout, @now),
					@locked = Locked,
					@lockAge = DATEDIFF(second, LockDate, @now),
					@lockCookie = LockCookie,
					@itemShort = CASE @locked
						WHEN 0 THEN SessionItemShort
						ELSE NULL
						END,
					@textptr = CASE @locked
						WHEN 0 THEN SessionItemLong
						ELSE NULL
						END,
					@length = CASE @locked
						WHEN 0 THEN DATALENGTH(SessionItemLong)
						ELSE NULL
						END
				WHERE SessionId = @id
				IF @length IS NOT NULL BEGIN
					SELECT @textptr
				END
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempGetStateItem3]
	@id         nvarchar(88),
    @itemShort  varbinary(7000) OUTPUT,
    @locked     bit OUTPUT,
    @lockAge    int OUTPUT,
    @lockCookie int OUTPUT,
    @actionFlags int OUTPUT
AS
    DECLARE @textptr AS tTextPtr
    DECLARE @length AS int
    DECLARE @now AS datetime
    SET @now = GETUTCDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE ASPStateTempSessions
				SET Expires = DATEADD(n, Timeout, @now),
					@locked = Locked,
					@lockAge = DATEDIFF(second, LockDate, @now),
					@lockCookie = LockCookie,
					@itemShort = CASE @locked
						WHEN 0 THEN SessionItemShort
						ELSE NULL
						END,
					@textptr = CASE @locked
						WHEN 0 THEN SessionItemLong
						ELSE NULL
						END,
					@length = CASE @locked
						WHEN 0 THEN DATALENGTH(SessionItemLong)
						ELSE NULL
						END,

					/* If the Uninitialized flag (0x1) if it is set,
						remove it and return InitializeItem (0x1) in actionFlags */
					Flags = CASE
						WHEN (Flags & 1) <> 0 THEN (Flags & ~1)
						ELSE Flags
						END,
					@actionFlags = CASE
						WHEN (Flags & 1) <> 0 THEN 1
						ELSE 0
						END
				WHERE SessionId = @id
				IF @length IS NOT NULL BEGIN
					SELECT @textptr
				END
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempGetStateItemExclusive]
    @id         tSessionId,
    @itemShort  tSessionItemShort OUTPUT,
    @locked     bit OUTPUT,
    @lockDate   datetime OUTPUT,
    @lockCookie int OUTPUT
AS
    DECLARE @textptr AS tTextPtr
    DECLARE @length AS int
    DECLARE @now AS datetime
    DECLARE @nowLocal AS datetime

    SET @now = GETUTCDATE()
    SET @nowLocal = GETDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE ASPStateTempSessions
				SET Expires = DATEADD(n, Timeout, @now),
					LockDate = CASE Locked
						WHEN 0 THEN @now
						ELSE LockDate
						END,
					@lockDate = LockDateLocal = CASE Locked
						WHEN 0 THEN @nowLocal
						ELSE LockDateLocal
						END,
					@lockCookie = LockCookie = CASE Locked
						WHEN 0 THEN LockCookie + 1
						ELSE LockCookie
						END,
					@itemShort = CASE Locked
						WHEN 0 THEN SessionItemShort
						ELSE NULL
						END,
					@textptr = CASE Locked
						WHEN 0 THEN SessionItemLong
						ELSE NULL
						END,
					@length = CASE Locked
						WHEN 0 THEN DATALENGTH(SessionItemLong)
						ELSE NULL
						END,
					@locked = Locked,
					Locked = 1
				WHERE SessionId = @id
				IF @length IS NOT NULL BEGIN
					SELECT @textptr
				END
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempGetStateItemExclusive2]
    @id         tSessionId,
    @itemShort  tSessionItemShort OUTPUT,
    @locked     bit OUTPUT,
    @lockAge    int OUTPUT,
    @lockCookie int OUTPUT
AS
    DECLARE @textptr AS tTextPtr
    DECLARE @length AS int
    DECLARE @now AS datetime
    DECLARE @nowLocal AS datetime

    SET @now = GETUTCDATE()
    SET @nowLocal = GETDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE ASPStateTempSessions
				SET Expires = DATEADD(n, Timeout, @now),
					LockDate = CASE Locked
						WHEN 0 THEN @now
						ELSE LockDate
						END,
					LockDateLocal = CASE Locked
						WHEN 0 THEN @nowLocal
						ELSE LockDateLocal
						END,
					@lockAge = CASE Locked
						WHEN 0 THEN 0
						ELSE DATEDIFF(second, LockDate, @now)
						END,
					@lockCookie = LockCookie = CASE Locked
						WHEN 0 THEN LockCookie + 1
						ELSE LockCookie
						END,
					@itemShort = CASE Locked
						WHEN 0 THEN SessionItemShort
						ELSE NULL
						END,
					@textptr = CASE Locked
						WHEN 0 THEN SessionItemLong
						ELSE NULL
						END,
					@length = CASE Locked
						WHEN 0 THEN DATALENGTH(SessionItemLong)
						ELSE NULL
						END,
					@locked = Locked,
					Locked = 1
				WHERE SessionId = @id
				IF @length IS NOT NULL BEGIN
					SELECT @textptr
				END
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempGetVersion]
    @ver      char(10) OUTPUT
AS
    SELECT @ver = '2'
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempInsertStateItemLong]
    @id         nvarchar(88),
    @itemLong   image,
    @timeout    int
AS
    DECLARE @now AS datetime
    DECLARE @nowLocal AS datetime

    SET @now = GETUTCDATE()
    SET @nowLocal = GETDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				INSERT ASPStateTempSessions
					(SessionId,
						SessionItemLong,
						Timeout,
						Expires,
						Locked,
						LockDate,
						LockDateLocal,
						LockCookie)
				VALUES
					(@id,
						@itemLong,
						@timeout,
						DATEADD(n, @timeout, @now),
						0,
						@now,
						@nowLocal,
						1)
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempInsertUninitializedItem]
    @id         nvarchar(88),
    @itemShort  varbinary(7000),
    @timeout    int
AS

    DECLARE @now AS datetime
    DECLARE @nowLocal AS datetime

    SET @now = GETUTCDATE()
    SET @nowLocal = GETDATE()

	DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				INSERT ASPStateTempSessions
					(SessionId,
					SessionItemShort,
					Timeout,
					Expires,
					Locked,
					LockDate,
					LockDateLocal,
					LockCookie,
					Flags)
				VALUES
					(@id,
					@itemShort,
					@timeout,
					DATEADD(n, @timeout, @now),
					0,
					@now,
					@nowLocal,
					1,
					1)
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempReleaseStateItemExclusive]
    @id         nvarchar(88),
    @lockCookie int
AS
DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE	ASPStateTempSessions
				SET		Expires = DATEADD(n, Timeout, GETUTCDATE()),
						Locked = 0
				WHERE	SessionId = @id AND LockCookie = @lockCookie
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop

    RETURN 0
GO

CREATE PROCEDURE [dbo].[TempRemoveStateItem]
    @id         nvarchar(88),
    @lockCookie int
AS

DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				DELETE	ASPStateTempSessions
				WHERE	SessionId = @id AND LockCookie = @lockCookie
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop
	RETURN 0
GO

CREATE PROCEDURE [dbo].[TempResetTimeout]
    @id         nvarchar(88)
AS
DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE	ASPStateTempSessions
				SET		Expires = DATEADD(n, Timeout, GETUTCDATE())
				WHERE	SessionId = @id
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop

	RETURN 0
GO

CREATE PROCEDURE [dbo].[TempUpdateStateItemShortNullLong]
    @id         nvarchar(88),
    @itemShort  varbinary(7000),
    @timeout    int,
    @lockCookie int
AS
DECLARE @retry INT = 10;
	
    WHILE (@retry > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
				UPDATE	ASPStateTempSessions
				SET		Expires = DATEADD(n, @timeout, GETUTCDATE()),
						SessionItemShort = @itemShort,
						SessionItemLong = NULL,
						Timeout = @timeout,
						Locked = 0
				WHERE	SessionId = @id AND LockCookie = @lockCookie
			COMMIT TRANSACTION;
            SET @retry = 0;  -- //Stops the loop.
        END TRY

        BEGIN CATCH
            SET @retry -= 1;

            IF (@retry > 0 AND
                ERROR_NUMBER() in (41302, 41305, 41325, 41301, 41839, 1205)
                )
            BEGIN
                IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                WAITFOR DELAY '00:00:00.001';
            END
            ELSE
            BEGIN
                PRINT 'Suffered an error for which Retry is inappropriate.';
				IF XACT_STATE() = -1
                    ROLLBACK TRANSACTION;

                THROW;
            END
        END CATCH

    END -- //While loop

    RETURN 0
GO
