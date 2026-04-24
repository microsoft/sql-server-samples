--Create the database
CREATE DATABASE WorldCup
GO
ALTER DATABASE [WorldCup] SET ALLOW_SNAPSHOT_ISOLATION ON
GO

USE WorldCup
GO
--Enable Automatic Digest Storage
--REPLACE <YourStorageAccountName> with the name of your Azure storage account.
ALTER DATABASE SCOPED CONFIGURATION
 SET LEDGER_DIGEST_STORAGE_ENDPOINT = 'https://<YourStorageAccountName>.blob.core.windows.net';
GO
--Create the table MoneyLine. This table will contain all the games and the odds
CREATE TABLE [dbo].[MoneyLine](
	[MoneyLineID] [int] IDENTITY(1,1) NOT NULL,
	[HomeCountry] [nvarchar](50) NOT NULL,
	[HomeCountryOdds] [INT] NOT NULL,
	[DrawOdds] [INT] NOT NULL,
	[VisitCountry] [nvarchar](50) NOT NULL,
	[VisitCountryOdds] [INT] NOT NULL,
	[GameDateTime] [datetime2] NOT NULL
	)
WITH
(
  SYSTEM_VERSIONING = ON,
  LEDGER = ON
);
GO

--Populate the MoneyLine table

INSERT INTO [dbo].[MoneyLine] ([HomeCountry], [HomeCountryOdds], [DrawOdds], [VisitCountry],[VisitCountryOdds],[GameDateTime])
VALUES ('Qatar', 250, 245, 'Ecuador',105,'2022-11-20 17:00:00'),
('England', -340, 390, 'Iran', 1000, '2022-11-21 14:00:00' ),
('Senegal', 475, 270, 'Netherlands',-165, '2022-11-21 17:00:00'),
('USA', 145, 205, 'Wales',205, '2022-11-21 20:00:00'),

('Argentina', -575, 600, 'Saudi Arabia',1500, '2022-11-22 11:00:00'),
('Denmark', -230, 340, 'Tunisia',600, '2022-11-22 14:00:00'),
('Mexico', 170, 215, 'Poland',165, '2022-11-22 17:00:00'),
('France', -550, 600, 'Australia',1300, '2022-11-22 20:00:00'),

('Morocco', 370, 230, 'Croatia',-125, '2022-11-23 11:00:00'),
('Germany', -280, 400, 'Japan',700, '2022-11-23 14:00:00'),
('Spain', -380, 475, 'Costa Rica',1000, '2022-11-23 17:00:00'),
('Belgium', -350, 450, 'Canada',900, '2022-11-23 20:00:00'),

('Switzerland', -120, 240, 'Cameroon',350, '2022-11-24 11:00:00'),
('Uruguay', -120, 235, 'South Korea',360, '2022-11-24 14:00:00'),
('Portugal', -210, 310, 'Ghana',600, '2022-11-24 17:00:00'),
('Brazil', -235, 350, 'Serbia',600, '2022-11-24 20:00:00'),

('Wales', 120, 215, 'Iran',250, '2022-11-25 11:00:00'),
('Qatar', 275, 225, 'Senegal',105, '2022-11-25 14:00:00'),
('Netherlands', 155, 300, 'Ecuador',390, '2022-11-25 17:00:00'),
('England', 140, 255, 'USA',400, '2022-11-25 20:00:00'),

('Tunisia', 190, 195, 'Australia',165, '2022-11-26 11:00:00'),
('Poland', -140, 255, 'Saudi Arabia',390, '2022-11-26 14:00:00'),
('France', -110, 240, 'Denmark',310, '2022-11-26 17:00:00'),
('Argentina', -170, 285, 'Mexico',475, '2022-11-26 20:00:00'),

('Japan', -105, 230, 'Costa Rica',310, '2022-11-27 11:00:00'),
('Belgium', -195, 310, 'Morocco',500, '2022-11-27 14:00:00'),
('Croatia', -130, 275, 'Canada',340, '2022-11-27 17:00:00'),
('Spain', 155, 230, 'Germany',170, '2022-11-27 20:00:00'),

('Cameroon', 300, 235, 'Serbia',-105, '2022-11-28 11:00:00'),
('South Korea', 145, 195, 'Ghana',210, '2022-11-28 14:00:00'),
('Brazil', -230, 340, 'Switzerland',600, '2022-11-28 17:00:00'),
('Portugal', 110, 225, 'Uruguay',260, '2022-11-28 20:00:00');

--Create the table Bets that will contain all the bets
CREATE TABLE [dbo].[Bets](
	[BetID] [int] IDENTITY(1,1) NOT NULL,
	[MoneylineID] [int] NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Country] [nvarchar](50),
	[Bet] [money] NOT NULL,
	[Payout] [money] NOT NULL,
	[BetDateTime] [datetime2] NOT NULL
	)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

-- Create a function to calculate the Payout
-- Calculating Payouts From Positive Moneyline Odds ---- Potential Profit = Stake x (Odds/100) + Stake
-- Calculating Payouts From Negative Moneyline Odds ---- Potential Profit = Stake / (Odds/100) + Stake
CREATE FUNCTION fn_CalculatePayout
(
	-- Add the parameters for the function here
	@Stake decimal(8,2), @Odds decimal(8,2)
)
RETURNS decimal(8,2)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Payout decimal(8,2)

	-- Add the T-SQL statements to compute the return value here
	IF @Odds > 0
		SET @Payout = @Stake * (@Odds/100) + @Stake
	ELSE
		SET @Payout = @Stake / (ABS(@Odds)/100) + @Stake

	-- Return the result of the function
	RETURN @Payout

END
GO


-- Create a stored procedure to place a bet
CREATE PROCEDURE usp_PlaceBet
	@MoneylineID INT,
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50),
	@Country NVARCHAR(50),
	@Bet MONEY,
	@Odds INT
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [dbo].[Bets] ([MoneylineID], [FirstName], [LastName], [Country], [Bet], [Payout],[BetDateTime]) VALUES (@MoneylineID, @FirstName, @LastName, @Country, @Bet, dbo.fn_CalculatePayout(@Odds,@Bet),GETDATE())
END
GO

-- Populate the bets table by executing the usp_PlaceBet stored procedure
  EXEC usp_PlaceBet @MoneylineID=1, @Firstname='Catherine', @LastName='Abel', @Country='Qatar', @Bet=150, @Odds=250
  EXEC usp_PlaceBet @MoneylineID=2, @Firstname='Brandon', @LastName='Flowers', @Country='England', @Bet=350, @Odds=-340
  EXEC usp_PlaceBet @MoneylineID=3, @Firstname='Lenny', @LastName='Kravitz', @Country='Netherlands', @Bet=250, @Odds=-165
  EXEC usp_PlaceBet @MoneylineID=8, @Firstname='Eric', @LastName='Clapton', @Country='France', @Bet=400, @Odds=-550
  EXEC usp_PlaceBet @MoneylineID=12, @Firstname='Johnny', @LastName='Cash', @Country='Belgium', @Bet=300, @Odds=-350
GO