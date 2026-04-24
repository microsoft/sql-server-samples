SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Employees](
	[EmployeeID] [int] IDENTITY(1,1) NOT NULL,
	[SSN] [char](11) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Salary] [money] NOT NULL
	)
WITH
(
  SYSTEM_VERSIONING = ON,
  LEDGER = ON
);
GO


CREATE TABLE [dbo].[AuditEvents](
	[Timestamp] [Datetime2] NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
	[UserName] [nvarchar](255) NOT NULL,
	[Query] [nvarchar](4000) NOT NULL
	)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

CREATE TABLE [dbo].[LedgerVerifications](
	[Timestamp] [Datetime2] NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
	[DigestLocations] [nvarchar](max) NOT NULL,
	[Result] [nvarchar](255) NOT NULL,
)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

CREATE PROCEDURE [dbo].[GetEmployeeLedgerEntries]
AS
BEGIN
	SET NOCOUNT ON
	SELECT
	t.[commit_time] AS [CommitTime]
	, t.[principal_name] AS [UserName]
	, l.EmployeeId
	, l.[SSN]
	, l.[FirstName]
	, l.[LastName]
	, l.[Salary]
	, l.[ledger_operation_type_desc] AS Operation
	FROM [dbo].[Employees_Ledger] l
	JOIN sys.database_ledger_transactions t
	ON t.transaction_id = l.ledger_transaction_id
	WHERE t.[commit_time] > DATEADD(MINUTE, -10, SYSDATETIMEOFFSET())
	ORDER BY t.commit_time DESC;
END;
GO

CREATE PROCEDURE [dbo].[VerifyLedger]
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @digest_locations NVARCHAR(MAX) = (SELECT path, last_digest_block_id, is_current FROM sys.database_ledger_digest_locations FOR JSON AUTO, INCLUDE_NULL_VALUES);
	BEGIN TRY
       EXEC sys.sp_verify_database_ledger_from_digest_storage @digest_locations;
       INSERT INTO [dbo].[LedgerVerifications] ([DigestLocations], [Result]) VALUES (@digest_locations, N'Success')
	END TRY
	BEGIN CATCH
       INSERT INTO [dbo].[LedgerVerifications] ([DigestLocations], [Result]) VALUES (@digest_locations, N'Failure')
	END CATCH
END;
GO

CREATE PROCEDURE [dbo].[GetLedgerVerifications]
AS
SET NOCOUNT ON
BEGIN
	SELECT *
	FROM [dbo].[LedgerVerifications]
	WHERE [Timestamp] > DATEADD(MINUTE, -60, SYSDATETIMEOFFSET())
	ORDER BY [Timestamp] DESC;
END;
GO

CREATE PROCEDURE [dbo].[GetAuditEvents]
AS
SET NOCOUNT ON
BEGIN
	SELECT *
	FROM [dbo].[AuditEvents]
	WHERE [Timestamp] > DATEADD(MINUTE, -10, SYSDATETIMEOFFSET())
	ORDER BY [Timestamp] DESC;
END;
GO

CREATE TABLE [AspNetRoles] (
    [Id] nvarchar(450) NOT NULL,
    [Name] nvarchar(256) NULL,
    [NormalizedName] nvarchar(256) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [AspNetUsers] (
    [Id] nvarchar(450) NOT NULL,
    [UserName] nvarchar(256) NULL,
    [NormalizedUserName] nvarchar(256) NULL,
    [Email] nvarchar(256) NULL,
    [NormalizedEmail] nvarchar(256) NULL,
    [EmailConfirmed] bit NOT NULL,
    [PasswordHash] nvarchar(max) NULL,
    [SecurityStamp] nvarchar(max) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    [PhoneNumber] nvarchar(max) NULL,
    [PhoneNumberConfirmed] bit NOT NULL,
    [TwoFactorEnabled] bit NOT NULL,
    [LockoutEnd] datetimeoffset NULL,
    [LockoutEnabled] bit NOT NULL,
    [AccessFailedCount] int NOT NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [AspNetRoleClaims] (
    [Id] int NOT NULL IDENTITY,
    [RoleId] nvarchar(450) NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [AspNetUserClaims] (
    [Id] int NOT NULL IDENTITY,
    [UserId] nvarchar(450) NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [AspNetUserLogins] (
    [LoginProvider] nvarchar(128) NOT NULL,
    [ProviderKey] nvarchar(128) NOT NULL,
    [ProviderDisplayName] nvarchar(max) NULL,
    [UserId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
    CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [AspNetUserRoles] (
    [UserId] nvarchar(450) NOT NULL,
    [RoleId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
    CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [AspNetUserTokens] (
    [UserId] nvarchar(450) NOT NULL,
    [LoginProvider] nvarchar(128) NOT NULL,
    [Name] nvarchar(128) NOT NULL,
    [Value] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
    CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO


CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [AspNetRoleClaims] ([RoleId]);
GO

CREATE UNIQUE INDEX [RoleNameIndex] ON [AspNetRoles] ([NormalizedName]) WHERE [NormalizedName] IS NOT NULL;
GO

CREATE INDEX [IX_AspNetUserClaims_UserId] ON [AspNetUserClaims] ([UserId]);
GO

CREATE INDEX [IX_AspNetUserLogins_UserId] ON [AspNetUserLogins] ([UserId]);
GO

CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [AspNetUserRoles] ([RoleId]);
GO

CREATE INDEX [EmailIndex] ON [AspNetUsers] ([NormalizedEmail]);
GO

CREATE UNIQUE INDEX [UserNameIndex] ON [AspNetUsers] ([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;
GO