CREATE PROCEDURE ReadMultipleReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN
	DECLARE @tranCount int = 0;
	DECLARE @CurrentSeq int = 0;
	DECLARE @Sum int = 0;
	DECLARE @loop int = 0;
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			SELECT @CurrentSeq = RAND() * IDENT_CURRENT(N'dbo.TicketReservationDetail')
			SET @loop = 0
			BEGIN TRAN
			WHILE (@loop < @RowsPerTransaction)
			BEGIN
				SELECT @Sum += FlightID from dbo.TicketReservationDetail where TicketReservationDetailID = @CurrentSeq - @loop;
				SET @loop += 1;
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
